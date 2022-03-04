use crate::services::row_kv::{RowKVPersistence, RowKVTransaction};
use flowy_collaboration::client_grid::{GridChange, GridPad};
use flowy_collaboration::entities::revision::Revision;
use flowy_collaboration::util::make_delta_from_revisions;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{GridId, RawRow};
use flowy_sync::{
    RevisionCloudService, RevisionCompact, RevisionManager, RevisionObjectBuilder, RevisionPersistence,
    RevisionWebSocket, RevisionWebSocketManager,
};
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use lib_sqlite::ConnectionPool;
use parking_lot::RwLock;
use std::sync::Arc;

pub struct ClientGridEditor {
    user_id: String,
    grid_id: GridId,
    grid: Arc<RwLock<GridPad>>,
    rev_manager: Arc<RevisionManager>,
    kv: Arc<RowKVPersistence>,
}

impl ClientGridEditor {
    pub async fn new(
        user_id: &str,
        grid_id: &GridId,
        token: &str,
        pool: Arc<ConnectionPool>,
        _web_socket: Arc<dyn RevisionWebSocket>,
    ) -> FlowyResult<Self> {
        let rev_persistence = Arc::new(RevisionPersistence::new(user_id, grid_id.as_ref(), pool.clone()));
        let mut rev_manager = RevisionManager::new(user_id, grid_id.as_ref(), rev_persistence);
        let cloud = Arc::new(GridRevisionCloudService {
            token: token.to_string(),
        });
        let grid = Arc::new(RwLock::new(
            rev_manager.load::<GridPadBuilder, GridRevisionCompact>(cloud).await?,
        ));
        let rev_manager = Arc::new(rev_manager);
        let kv = Arc::new(RowKVPersistence::new(pool));

        let user_id = user_id.to_owned();
        let grid_id = grid_id.to_owned();
        Ok(Self {
            user_id,
            grid_id,
            grid,
            rev_manager,
            kv,
        })
    }

    pub async fn create_row(&self, row: RawRow) -> FlowyResult<()> {
        let _ = self
            .modify(|grid| {
                let change = grid.create_row(&row)?;
                Ok(change)
            })
            .await?;

        let _ = self.kv.set(row)?;
        Ok(())
    }

    pub async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: FnOnce(&mut GridPad) -> FlowyResult<Option<GridChange>>,
    {
        let mut write_guard = self.grid.write();
        match f(&mut *write_guard)? {
            None => {}
            Some(change) => {
                let _ = self.apply_change(change).await?;
            }
        }
        Ok(())
    }

    async fn apply_change(&self, change: GridChange) -> FlowyResult<()> {
        let GridChange { delta, md5 } = change;
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.to_bytes();
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &self.user_id,
            md5,
        );
        let _ = self
            .rev_manager
            .add_local_revision::<GridRevisionCompact>(&revision)
            .await?;
        Ok(())
    }
}

struct GridPadBuilder();
impl RevisionObjectBuilder for GridPadBuilder {
    type Output = GridPad;

    fn build_object(_object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridPad::from_revisions(revisions)?;
        Ok(pad)
    }
}

struct GridRevisionCloudService {
    #[allow(dead_code)]
    token: String,
}

impl RevisionCloudService for GridRevisionCloudService {
    #[tracing::instrument(level = "trace", skip(self))]
    fn fetch_object(&self, _user_id: &str, _object_id: &str) -> FutureResult<Vec<Revision>, FlowyError> {
        FutureResult::new(async move { Ok(vec![]) })
    }
}

struct GridRevisionCompact();
impl RevisionCompact for GridRevisionCompact {
    fn compact_revisions(user_id: &str, object_id: &str, mut revisions: Vec<Revision>) -> FlowyResult<Revision> {
        if revisions.is_empty() {
            return Err(FlowyError::internal().context("Can't compact the empty folder's revisions"));
        }

        if revisions.len() == 1 {
            return Ok(revisions.pop().unwrap());
        }

        let first_revision = revisions.first().unwrap();
        let last_revision = revisions.last().unwrap();

        let (base_rev_id, rev_id) = first_revision.pair_rev_id();
        let md5 = last_revision.md5.clone();
        let delta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        let delta_data = delta.to_bytes();
        Ok(Revision::new(object_id, base_rev_id, rev_id, delta_data, user_id, md5))
    }
}
