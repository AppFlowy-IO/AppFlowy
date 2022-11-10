use crate::services::filter::FilterController;
use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher, TaskHandler};
use lib_infra::future::BoxResultFuture;
use std::sync::Arc;
use tokio::sync::RwLock;

pub const FILTER_HANDLER_ID: &str = "grid_filter";

pub(crate) struct FilterTaskHandler {
    scheduler: Arc<RwLock<TaskDispatcher>>,
    filter_controller: Arc<FilterController>,
}

impl FilterTaskHandler {
    pub(crate) fn new(scheduler: Arc<RwLock<TaskDispatcher>>, filter_controller: Arc<FilterController>) -> Self {
        Self {
            scheduler,
            filter_controller,
        }
    }

    pub(crate) async fn gen_task(&mut self, predicate: &str) {
        let task_id = self.scheduler.read().await.next_task_id();
        let task = Task::new(
            FILTER_HANDLER_ID,
            task_id,
            TaskContent::Text(predicate.to_owned()),
            QualityOfService::UserInteractive,
        );
        self.scheduler.write().await.add_task(task);
    }
}

impl TaskHandler for FilterTaskHandler {
    fn handler_id(&self) -> &str {
        FILTER_HANDLER_ID
    }

    fn run(&self, content: TaskContent) -> BoxResultFuture<(), anyhow::Error> {
        let filter_service = self.filter_controller.clone();
        Box::pin(async move {
            if let TaskContent::Text(predicate) = content {
                // let _ = filter_service.process(&predicate).await?;
            }
            Ok(())
        })
    }
}
