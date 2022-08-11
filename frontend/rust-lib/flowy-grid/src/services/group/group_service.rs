use crate::services::block_manager::GridBlockManager;
use crate::services::grid_editor_task::GridServiceTaskScheduler;
use flowy_sync::client_grid::GridRevisionPad;
use std::sync::Arc;
use tokio::sync::RwLock;

pub(crate) struct GridGroupService {
    #[allow(dead_code)]
    scheduler: Arc<dyn GridServiceTaskScheduler>,
    #[allow(dead_code)]
    grid_pad: Arc<RwLock<GridRevisionPad>>,
    #[allow(dead_code)]
    block_manager: Arc<GridBlockManager>,
}

impl GridGroupService {
    pub(crate) async fn new<S: GridServiceTaskScheduler>(
        grid_pad: Arc<RwLock<GridRevisionPad>>,
        block_manager: Arc<GridBlockManager>,
        scheduler: S,
    ) -> Self {
        let scheduler = Arc::new(scheduler);
        Self {
            scheduler,
            grid_pad,
            block_manager,
        }
    }
}
