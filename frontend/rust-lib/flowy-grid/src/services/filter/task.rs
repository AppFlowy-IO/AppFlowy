use crate::services::filter::FilterController;
use flowy_task::{TaskContent, TaskHandler};
use lib_infra::future::BoxResultFuture;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct FilterTaskHandler {
    handler_id: String,
    filter_controller: Arc<RwLock<FilterController>>,
}

impl FilterTaskHandler {
    pub fn new(handler_id: String, filter_controller: Arc<RwLock<FilterController>>) -> Self {
        Self {
            handler_id,
            filter_controller,
        }
    }
}

impl TaskHandler for FilterTaskHandler {
    fn handler_id(&self) -> &str {
        &self.handler_id
    }

    fn run(&self, content: TaskContent) -> BoxResultFuture<(), anyhow::Error> {
        let filter_controller = self.filter_controller.clone();
        Box::pin(async move {
            if let TaskContent::Text(predicate) = content {
                let _ = filter_controller
                    .write()
                    .await
                    .process(&predicate)
                    .await
                    .map_err(anyhow::Error::from);
            }
            Ok(())
        })
    }
}
