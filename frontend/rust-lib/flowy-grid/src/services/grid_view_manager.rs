use crate::entities::{
    CreateRowParams, GridFilterConfiguration, GridLayout, GridSettingPB, MoveRowParams, RepeatedGridGroupPB, RowPB,
};
use crate::manager::GridUser;

use crate::services::grid_editor_task::GridServiceTaskScheduler;
use crate::services::grid_view_editor::GridViewRevisionEditor;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::{FieldRevision, RowRevision};
use flowy_revision::disk::SQLiteGridViewRevisionPersistence;
use flowy_revision::{RevisionCompactor, RevisionManager, RevisionPersistence, SQLiteRevisionSnapshotPersistence};

use flowy_sync::entities::grid::GridSettingChangesetParams;
use flowy_sync::entities::revision::Revision;
use flowy_sync::util::make_text_delta_from_revisions;
use lib_infra::future::AFFuture;
use std::sync::Arc;

type ViewId = String;

pub trait GridViewFieldDelegate: Send + Sync + 'static {
    fn get_field_revs(&self) -> AFFuture<Vec<Arc<FieldRevision>>>;
    fn get_field_rev(&self, field_id: &str) -> AFFuture<Option<Arc<FieldRevision>>>;
}

pub trait GridViewRowDelegate: Send + Sync + 'static {
    fn gv_index_of_row(&self, row_id: &str) -> AFFuture<Option<usize>>;
    fn gv_get_row_rev(&self, row_id: &str) -> AFFuture<Option<Arc<RowRevision>>>;
    fn gv_row_revs(&self) -> AFFuture<Vec<Arc<RowRevision>>>;
}

pub trait GridViewRowOperation: Send + Sync + 'static {
    // Will be removed in the future.
    fn gv_move_row(&self, row_rev: Arc<RowRevision>, from: usize, to: usize) -> AFFuture<FlowyResult<()>>;
}

pub(crate) struct GridViewManager {
    grid_id: String,
    user: Arc<dyn GridUser>,
    field_delegate: Arc<dyn GridViewFieldDelegate>,
    row_delegate: Arc<dyn GridViewRowDelegate>,
    row_operation: Arc<dyn GridViewRowOperation>,
    view_editors: DashMap<ViewId, Arc<GridViewRevisionEditor>>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
}

impl GridViewManager {
    pub(crate) async fn new(
        grid_id: String,
        user: Arc<dyn GridUser>,
        field_delegate: Arc<dyn GridViewFieldDelegate>,
        row_delegate: Arc<dyn GridViewRowDelegate>,
        row_operation: Arc<dyn GridViewRowOperation>,
        scheduler: Arc<dyn GridServiceTaskScheduler>,
    ) -> FlowyResult<Self> {
        Ok(Self {
            grid_id,
            user,
            scheduler,
            field_delegate,
            row_delegate,
            row_operation,
            view_editors: DashMap::default(),
        })
    }

    pub(crate) async fn fill_row(&self, row_rev: &mut RowRevision, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.fill_row(row_rev, params).await;
        }
    }

    pub(crate) async fn did_update_row(&self, row_id: &str) {
        match self.row_delegate.gv_get_row_rev(row_id).await {
            None => {
                tracing::warn!("Can not find the row in grid view");
            }
            Some(row_rev) => {
                for view_editor in self.view_editors.iter() {
                    view_editor.did_update_row(&row_rev).await;
                }
            }
        }
    }

    pub(crate) async fn did_create_row(&self, row_pb: &RowPB, params: &CreateRowParams) {
        for view_editor in self.view_editors.iter() {
            view_editor.did_create_row(row_pb, params).await;
        }
    }

    pub(crate) async fn did_delete_row(&self, row_id: &str) {
        for view_editor in self.view_editors.iter() {
            view_editor.did_delete_row(row_id).await;
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

    pub(crate) async fn move_row(&self, params: MoveRowParams) -> FlowyResult<()> {
        let MoveRowParams {
            view_id: _,
            row_id,
            from_index,
            to_index,
            layout,
            upper_row_id,
        } = params;

        let from_index = from_index as usize;

        match self.row_delegate.gv_get_row_rev(&row_id).await {
            None => tracing::warn!("Move row failed, can not find the row:{}", row_id),
            Some(row_rev) => match layout {
                GridLayout::Table => {
                    tracing::trace!("Move row from {} to {}", from_index, to_index);
                    let to_index = to_index as usize;
                    let _ = self.row_operation.gv_move_row(row_rev, from_index, to_index).await?;
                }
                GridLayout::Board => {
                    if let Some(upper_row_id) = upper_row_id {
                        if let Some(to_index) = self.row_delegate.gv_index_of_row(&upper_row_id).await {
                            tracing::trace!("Move row from {} to {}", from_index, to_index);
                            let _ = self.row_operation.gv_move_row(row_rev, from_index, to_index).await?;
                        }
                    }
                }
            },
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
                        self.field_delegate.clone(),
                        self.row_delegate.clone(),
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
        self.get_view_editor(&self.grid_id).await
    }
}

async fn make_view_editor(
    user: &Arc<dyn GridUser>,
    view_id: &str,
    field_delegate: Arc<dyn GridViewFieldDelegate>,
    row_delegate: Arc<dyn GridViewRowDelegate>,
    scheduler: Arc<dyn GridServiceTaskScheduler>,
) -> FlowyResult<GridViewRevisionEditor> {
    tracing::trace!("Open view:{} editor", view_id);

    let rev_manager = make_grid_view_rev_manager(user, view_id).await?;
    let user_id = user.user_id()?;
    let token = user.token()?;
    let view_id = view_id.to_owned();
    GridViewRevisionEditor::new(
        &user_id,
        &token,
        view_id,
        field_delegate,
        row_delegate,
        scheduler,
        rev_manager,
    )
    .await
}

pub async fn make_grid_view_rev_manager(user: &Arc<dyn GridUser>, view_id: &str) -> FlowyResult<RevisionManager> {
    tracing::trace!("Open view:{} editor", view_id);
    let user_id = user.user_id()?;
    let pool = user.db_pool()?;

    let disk_cache = SQLiteGridViewRevisionPersistence::new(&user_id, pool.clone());
    let rev_persistence = RevisionPersistence::new(&user_id, view_id, disk_cache);
    let rev_compactor = GridViewRevisionCompactor();

    let snapshot_persistence = SQLiteRevisionSnapshotPersistence::new(view_id, pool);
    Ok(RevisionManager::new(
        &user_id,
        view_id,
        rev_persistence,
        rev_compactor,
        snapshot_persistence,
    ))
}

pub struct GridViewRevisionCompactor();
impl RevisionCompactor for GridViewRevisionCompactor {
    fn bytes_from_revisions(&self, revisions: Vec<Revision>) -> FlowyResult<Bytes> {
        let delta = make_text_delta_from_revisions(revisions)?;
        Ok(delta.json_bytes())
    }
}
