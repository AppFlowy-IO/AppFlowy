use crate::services::block_manager::GridBlockManager;
use crate::services::grid_view_editor::GridViewEditorDelegate;
use flowy_sync::client_grid::GridRevisionPad;
use flowy_task::TaskDispatcher;
use grid_rev_model::{FieldRevision, RowRevision};
use lib_infra::future::{wrap_future, AFFuture};
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridViewEditorDelegateImpl {
    pub(crate) pad: Arc<RwLock<GridRevisionPad>>,
    pub(crate) block_manager: Arc<GridBlockManager>,
    pub(crate) task_scheduler: Arc<RwLock<TaskDispatcher>>,
}

impl GridViewEditorDelegate for GridViewEditorDelegateImpl {
    fn get_field_revs(&self, field_ids: Option<Vec<String>>) -> AFFuture<Vec<Arc<FieldRevision>>> {
        let pad = self.pad.clone();
        wrap_future(async move {
            match pad.read().await.get_field_revs(field_ids) {
                Ok(field_revs) => field_revs,
                Err(e) => {
                    tracing::error!("[GridViewRevisionDelegate] get field revisions failed: {}", e);
                    vec![]
                }
            }
        })
    }

    fn get_field_rev(&self, field_id: &str) -> AFFuture<Option<Arc<FieldRevision>>> {
        let pad = self.pad.clone();
        let field_id = field_id.to_owned();
        wrap_future(async move { Some(pad.read().await.get_field_rev(&field_id)?.1.clone()) })
    }

    fn index_of_row(&self, row_id: &str) -> AFFuture<Option<usize>> {
        let block_manager = self.block_manager.clone();
        let row_id = row_id.to_owned();
        wrap_future(async move { block_manager.index_of_row(&row_id).await })
    }

    fn get_row_rev(&self, row_id: &str) -> AFFuture<Option<Arc<RowRevision>>> {
        let block_manager = self.block_manager.clone();
        let row_id = row_id.to_owned();
        wrap_future(async move {
            match block_manager.get_row_rev(&row_id).await {
                Ok(row_rev) => row_rev,
                Err(_) => None,
            }
        })
    }

    fn get_row_revs(&self) -> AFFuture<Vec<Arc<RowRevision>>> {
        let block_manager = self.block_manager.clone();

        wrap_future(async move {
            let blocks = block_manager.get_block_snapshots(None).await.unwrap();
            blocks
                .into_iter()
                .flat_map(|block| block.row_revs)
                .collect::<Vec<Arc<RowRevision>>>()
        })
    }

    fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>> {
        self.task_scheduler.clone()
    }
}
