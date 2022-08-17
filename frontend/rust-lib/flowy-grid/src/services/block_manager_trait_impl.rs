use crate::services::block_manager::GridBlockManager;
use crate::services::grid_view_manager::GridViewRowDelegate;
use flowy_error::FlowyResult;
use flowy_grid_data_model::revision::RowRevision;
use lib_infra::future::{wrap_future, AFFuture};
use std::sync::Arc;

impl GridViewRowDelegate for Arc<GridBlockManager> {
    fn gv_index_of_row(&self, row_id: &str) -> AFFuture<Option<usize>> {
        let block_manager = self.clone();
        let row_id = row_id.to_owned();
        wrap_future(async move { block_manager.index_of_row(&row_id).await })
    }

    fn gv_get_row_rev(&self, row_id: &str) -> AFFuture<Option<Arc<RowRevision>>> {
        let block_manager = self.clone();
        let row_id = row_id.to_owned();
        wrap_future(async move {
            match block_manager.get_row_rev(&row_id).await {
                Ok(row_rev) => row_rev,
                Err(_) => None,
            }
        })
    }

    fn gv_row_revs(&self) -> AFFuture<Vec<Arc<RowRevision>>> {
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
