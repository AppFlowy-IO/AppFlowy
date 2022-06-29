use crate::manager::GridTaskSchedulerRwLock;
use crate::services::block_manager::GridBlockManager;
use crate::services::tasks::Task;
use flowy_error::FlowyResult;

use flowy_sync::client_grid::GridRevisionPad;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridFilterService {
    #[allow(dead_code)]
    scheduler: GridTaskSchedulerRwLock,
    #[allow(dead_code)]
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    #[allow(dead_code)]
    block_manager: Arc<GridBlockManager>,
}
impl GridFilterService {
    pub fn new(
        grid_pad: Arc<RwLock<GridRevisionPad>>,
        block_manager: Arc<GridBlockManager>,
        scheduler: GridTaskSchedulerRwLock,
    ) -> Self {
        Self {
            grid_pad,
            block_manager,
            scheduler,
        }
    }

    pub async fn process_task(&self, _task: Task) -> FlowyResult<()> {
        Ok(())
    }

    pub async fn notify_changed(&self) {
        //
        // let grid_pad = self.grid_pad.read().await;
        // match grid_pad.get_filters(None) {
        //     None => {}
        //     Some(filter_revs) => {
        //         filter_revs
        //             .iter()
        //             .for_each(|filter_rev| match grid_pad.get_field_rev(&filter_rev.field_id) {
        //                 None => {}
        //                 Some((_, _field_rev)) => match field_rev.field_type {
        //                     FieldType::RichText => {}
        //                     FieldType::Number => {}
        //                     FieldType::DateTime => {}
        //                     FieldType::SingleSelect => {}
        //                     FieldType::MultiSelect => {}
        //                     FieldType::Checkbox => {}
        //                     FieldType::URL => {}
        //                 },
        //             });
        //     }
        // }
    }
}
