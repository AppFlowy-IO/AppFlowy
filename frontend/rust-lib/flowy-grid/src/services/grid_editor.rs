use crate::manager::GridUser;
use crate::services::kv_persistence::{GridKVPersistence, KVTransaction};

use crate::services::grid_meta_editor::GridBlockMetaEditorManager;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::client_grid::{GridChange, GridMetaPad};
use flowy_collaboration::entities::revision::Revision;
use flowy_collaboration::util::make_delta_from_revisions;
use flowy_error::{FlowyError, FlowyResult};
use flowy_grid_data_model::entities::{
    Field, FieldChangeset, Grid, GridBlock, GridBlockChangeset, RepeatedFieldOrder, RepeatedRowOrder, Row,
};

use flowy_sync::{RevisionCloudService, RevisionCompactor, RevisionManager, RevisionObjectBuilder};
use lib_infra::future::FutureResult;
use lib_ot::core::PlainTextAttributes;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct ClientGridEditor {
    grid_id: String,
    user: Arc<dyn GridUser>,
    grid_meta_pad: Arc<RwLock<GridMetaPad>>,
    rev_manager: Arc<RevisionManager>,
    block_meta_manager: Arc<GridBlockMetaEditorManager>,
    kv_persistence: Arc<GridKVPersistence>,
}

impl ClientGridEditor {
    pub async fn new(
        grid_id: &str,
        user: Arc<dyn GridUser>,
        mut rev_manager: RevisionManager,
        kv_persistence: Arc<GridKVPersistence>,
    ) -> FlowyResult<Arc<Self>> {
        let token = user.token()?;
        let cloud = Arc::new(GridRevisionCloudService { token });
        let grid_pad = rev_manager.load::<GridPadBuilder>(Some(cloud)).await?;
        let rev_manager = Arc::new(rev_manager);
        let grid_meta_pad = Arc::new(RwLock::new(grid_pad));

        let block_meta_manager =
            Arc::new(GridBlockMetaEditorManager::new(&user, grid_meta_pad.read().await.get_blocks().clone()).await?);

        Ok(Arc::new(Self {
            grid_id: grid_id.to_owned(),
            user,
            grid_meta_pad,
            rev_manager,
            block_meta_manager,
            kv_persistence,
        }))
    }

    pub async fn create_field(&self, field: Field) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.create_field(field)?)).await?;
        Ok(())
    }

    pub async fn update_field(&self, change: FieldChangeset) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.update_field(change)?)).await?;
        Ok(())
    }

    pub async fn delete_field(&self, field_id: &str) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.delete_field(field_id)?)).await?;
        Ok(())
    }

    pub async fn create_block(&self, grid_block: GridBlock) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.create_block(grid_block)?)).await?;
        Ok(())
    }

    pub async fn update_block(&self, change: GridBlockChangeset) -> FlowyResult<()> {
        let _ = self.modify(|grid| Ok(grid.update_block(change)?)).await?;
        Ok(())
    }

    pub async fn create_row(&self) -> FlowyResult<()> {
        let fields = self.grid_meta_pad.read().await.get_fields(None)?;
        let grid_block = match self.grid_meta_pad.read().await.get_blocks().last() {
            None => Err(FlowyError::internal().context("There is no grid block in this grid")),
            Some(grid_block) => Ok(grid_block.clone()),
        }?;

        let row_count = self.block_meta_manager.create_row(fields, &grid_block).await?;
        let change = GridBlockChangeset::from_row_count(&grid_block.id, row_count);
        let _ = self.update_block(change).await?;
        Ok(())
    }

    pub async fn get_rows(&self, row_orders: RepeatedRowOrder) -> FlowyResult<Vec<Row>> {
        let fields = self.grid_meta_pad.read().await.get_fields(None)?;
        let rows = self.block_meta_manager.get_rows(fields, row_orders).await?;
        Ok(rows)
    }

    pub async fn get_all_rows(&self) -> FlowyResult<Vec<Row>> {
        let fields = self.grid_meta_pad.read().await.get_fields(None)?;
        let grid_blocks = self.grid_meta_pad.read().await.get_blocks();
        self.block_meta_manager.get_all_rows(grid_blocks, fields).await
    }

    pub async fn delete_rows(&self, row_orders: Option<RepeatedRowOrder>) -> FlowyResult<()> {
        let row_counts = self.block_meta_manager.delete_rows(row_orders).await?;
        for (block_id, row_count) in row_counts {
            let _ = self
                .update_block(GridBlockChangeset::from_row_count(&block_id, row_count))
                .await?;
        }

        Ok(())
    }

    pub async fn grid_data(&self) -> Grid {
        todo!()
    }

    pub async fn get_fields(&self, field_orders: Option<RepeatedFieldOrder>) -> FlowyResult<Vec<Field>> {
        let fields = self.grid_meta_pad.read().await.get_fields(field_orders)?;
        Ok(fields)
    }

    pub async fn get_blocks(&self) -> FlowyResult<Vec<GridBlock>> {
        let grid_blocks = self.grid_meta_pad.read().await.get_blocks();
        Ok(grid_blocks)
    }

    pub async fn delta_str(&self) -> String {
        self.grid_meta_pad.read().await.delta_str()
    }

    async fn modify<F>(&self, f: F) -> FlowyResult<()>
    where
        F: for<'a> FnOnce(&'a mut GridMetaPad) -> FlowyResult<Option<GridChange>>,
    {
        let mut write_guard = self.grid_meta_pad.write().await;
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
        let user_id = self.user.user_id()?;
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id_pair();
        let delta_data = delta.to_bytes();
        let revision = Revision::new(
            &self.rev_manager.object_id,
            base_rev_id,
            rev_id,
            delta_data,
            &user_id,
            md5,
        );
        let _ = self
            .rev_manager
            .add_local_revision(&revision, Box::new(GridRevisionCompactor()))
            .await?;
        Ok(())
    }
}

#[cfg(feature = "flowy_unit_test")]
impl ClientGridEditor {
    pub fn rev_manager(&self) -> Arc<RevisionManager> {
        self.rev_manager.clone()
    }
}

async fn load_all_fields(
    grid_pad: &GridMetaPad,
    kv_persistence: &Arc<GridKVPersistence>,
) -> FlowyResult<DashMap<String, Field>> {
    let field_ids = grid_pad
        .fields()
        .iter()
        .map(|field| field.id.clone())
        .collect::<Vec<_>>();

    let fields = kv_persistence.batch_get::<Field>(field_ids)?;
    let map = DashMap::new();
    for field in fields {
        map.insert(field.id.clone(), field);
    }
    Ok(map)
}

pub struct GridPadBuilder();
impl RevisionObjectBuilder for GridPadBuilder {
    type Output = GridMetaPad;

    fn build_object(object_id: &str, revisions: Vec<Revision>) -> FlowyResult<Self::Output> {
        let pad = GridMetaPad::from_revisions(object_id, revisions)?;
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

struct GridRevisionCompactor();
impl RevisionCompactor for GridRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        Ok(delta.to_bytes())
    }
}
