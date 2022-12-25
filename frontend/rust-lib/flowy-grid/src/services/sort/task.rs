use crate::services::sort::SortController;
use flowy_task::{TaskContent, TaskHandler};
use lib_infra::future::BoxResultFuture;
use std::sync::Arc;
use tokio::sync::RwLock;

pub struct SortTaskHandler {
    handler_id: String,
    #[allow(dead_code)]
    sort_controller: Arc<RwLock<SortController>>,
}

impl SortTaskHandler {
    pub fn new(handler_id: String, sort_controller: Arc<RwLock<SortController>>) -> Self {
        Self {
            handler_id,
            sort_controller,
        }
    }
}

impl TaskHandler for SortTaskHandler {
    fn handler_id(&self) -> &str {
        &self.handler_id
    }

    fn run(&self, content: TaskContent) -> BoxResultFuture<(), anyhow::Error> {
        let sort_controller = self.sort_controller.clone();
        Box::pin(async move {
            if let TaskContent::Text(predicate) = content {
                let _ = sort_controller
                    .write()
                    .await
                    .process(&predicate)
                    .await
                    .map_err(anyhow::Error::from)?;
            }
            Ok(())
        })
    }
}
