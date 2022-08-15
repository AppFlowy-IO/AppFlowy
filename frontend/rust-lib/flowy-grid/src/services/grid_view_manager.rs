use crate::manager::GridUser;
use crate::services::grid_view_editor::{GridViewRevisionDataSource, GridViewRevisionDelegate, GridViewRevisionEditor};
use bytes::Bytes;

use crate::entities::{CreateRowParams, GridFilterConfiguration, GridSettingPB, RepeatedGridGroupPB, RowPB};
use crate::services::grid_editor_task::GridServiceTaskScheduler;

use crate::services::block_manager::GridBlockManager;
use dashmap::DashMap;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use flowy_revision::disk::SQLiteGridViewRevisionPersistence;
use flowy_revision::{RevisionCompactor, RevisionManager, RevisionPersistence, SQLiteRevisionSnapshotPersistence};
use flowy_sync::client_grid::GridRevisionPad;
use flowy_sync::entities::revision::Revision;

use flowy_sync::util::make_text_delta_from_revisions;

use flowy_sync::entities::grid::GridSettingChangesetParams;

use lib_infra::future::{wrap_future, AFFuture};
use std::sync::Arc;
use tokio::sync::RwLock;

type ViewId = String;

pub(crate) struct GridViewManager {
    user: Arc<dyn GridUser>,
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    block_manager: Arc<GridBlockManager>,
    view_editors: DashMap<ViewId, Arc<GridViewRevisionEditor>>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
}

impl GridViewManager {
    pub(crate) async fn new(
        user: Arc<dyn GridUser>,
        grid_pad: Arc<RwLock<GridRevisionPad>>,
        block_manager: Arc<GridBlockManager>,
        scheduler: Arc<dyn GridServiceTaskScheduler>,
    ) -> FlowyResult<Self> {
        Ok(Self {
            user,
            grid_pad,
            scheduler,
            block_manager,
            view_editors: DashMap::default(),
        })
    }

    pub(crate) async fn update_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.create_row(row_rev, params).await;
        }
    }

    pub(crate) async fn did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.did_create_row(row_pb, params).await;
        }
    }

    pub(crate) async fn delete_row(&self, row_id: &str) {
        for view_editor in self.view_editors.iter() {
            view_editor.delete_row(row_id).await;
        }
    }

    pub(crate) async fn get_setting(&self) -> FlowyResult<GridSettingPB> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_setting().await)
    }

    pub(crate) async fn update_setting(&self, params: GridSettingChangesetParams) -> FlowyResult<()> {
        let view_editor = self.get_default_view_editor().await?;
        let _ = view_editor.update_setting(params).await?;
        Ok(())
    }

    pub(crate) async fn get_filters(&self) -> FlowyResult<Vec<GridFilterConfiguration>> {
        let view_editor = self.get_default_view_editor().await?;
        Ok(view_editor.get_filters().await)
    }

    pub(crate) async fn load_groups(&self) -> FlowyResult<RepeatedGridGroupPB> {
        let view_editor = self.get_default_view_editor().await?;
        let groups = view_editor.load_groups().await?;
        Ok(RepeatedGridGroupPB { items: groups })
    }

    pub(crate) async fn move_row(&self, row_id: &str, from: i32, to: i32) -> FlowyResult<()> {
        match self.block_manager.get_row_rev(row_id).await? {
            None => tracing::warn!("Move row failed, can not find the row:{}", row_id),
            Some(row_rev) => {
                let _ = self
                    .block_manager
                    .move_row(row_rev.clone(), from as usize, to as usize)
                    .await?;
            }
        }
        Ok(())
    }

    pub(crate) async fn get_view_editor(&self, view_id: &str) -> FlowyResult<Arc<GridViewRevisionEditor>> {
        debug_assert!(!view_id.is_empty());
        match self.view_editors.get(view_id) {
            None => {
                let editor = Arc::new(
                    make_view_editor(
                        &self.user,
                        view_id,
                        self.grid_pad.clone(),
                        self.block_manager.clone(),
                        self.scheduler.clone(),
                    )
                    .await?,
                );
                self.view_editors.insert(view_id.to_owned(), editor.clone());
                Ok(editor)
            }
            Some(view_editor) => Ok(view_editor.clone()),
        }
    }

    async fn get_default_view_editor(&self) -> FlowyResult<Arc<GridViewRevisionEditor>> {
        let grid_id = self.grid_pad.read().await.grid_id();
        self.get_view_editor(&grid_id).await
    }
}

async fn make_view_editor<Delegate, DataSource>(
    user: &Arc<dyn GridUser>,
    view_id: &str,
    delegate: Delegate,
    data_source: DataSource,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
) -> FlowyResult<GridViewRevisionEditor>
where
    Delegate: GridViewRevisionDelegate,
    DataSource: GridViewRevisionDataSource,
{
    tracing::trace!("Open view:{} editor", view_id);
    let token = user.token()?;
    let user_id = user.user_id()?;
    let pool = user.db_pool()?;
    let view_id = view_id.to_owned();

    let disk_cache = SQLiteGridViewRevisionPersistence::new(&user_id, pool.clone());
    let rev_persistence = RevisionPersistence::new(&user_id, &view_id, disk_cache);
    let rev_compactor = GridViewRevisionCompactor();

    let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(&view_id, pool);
    let rev_manager = RevisionManager::new(&user_id, &view_id, rev_persistence, rev_compactor, snapshot_persistence);
    GridViewRevisionEditor::new(&user_id, &token, view_id, delegate, data_source, scheduler, rev_manager).await
}

pub struct GridViewRevisionCompactor();
impl RevisionCompactor for GridViewRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_text_delta_from_revisions(revisions)?;
        Ok(delta.json_bytes())
    }
}

impl GridViewRevisionDataSource for Arc<GridBlockManager> {
    fn row_revs(&self) -> AFFuture<Vec<Arc<RowRevision>>> {
        let block_manager = self.clone();

        wrap_future(async move {
            let blocks = block_manager.get_block_snapshots(None).await.unwrap();
            blocks
                .into_iter()
                .map(|block| block.row_revs)
                .flatten()
                .collect::<Vec<Arc<RowRevision>>>()
        })
    }
}

impl GridViewRevisionDelegate for Arc<RwLock<GridRevisionPad>> {
    fn get_field_revs(&self) -> AFFuture<Vec<Arc<FieldRevision>>> {
        let pad = self.clone();
        wrap_future(async move {
            match pad.read().await.get_field_revs(None) {
                Ok(field_revs) => field_revs,
                Err(e) => {
                    tracing::error!("[GridViewRevisionDelegate] get field revisions failed: {}", e);
                    vec![]
                }
            }
        })
    }

    fn get_field_rev(&self, field_id: &str) -> AFFuture<Option<Arc<FieldRevision>>> {
        let pad = self.clone();
        let field_id = field_id.to_owned();
        wrap_future(async move {
            pad.read()
                .await
                .get_field_rev(&field_id)
                .map(|(_, field_rev)| field_rev.clone())
        })
    }
}
