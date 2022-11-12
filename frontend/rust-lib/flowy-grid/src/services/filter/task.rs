use crate::services::filter::FilterController;
use flowy_task::{TaskContent, TaskHandler};
use lib_infra::future::BoxResultFuture;
use std::sync::Arc;
use tokio::sync::RwLock;

pub const FILTER_HANDLER_ID: &str = "grid_filter";

pub struct FilterTaskHandler(Arc<RwLock<FilterController>>);
impl FilterTaskHandler {
    pub fn new(filter_controller: Arc<RwLock<FilterController>>) -> Self {
        Self(filter_controller)
    }
}

impl TaskHandler for FilterTaskHandler {
    fn handler_id(&self) -> &str {
        FILTER_HANDLER_ID
    }

    fn run(&self, content: TaskContent) -> BoxResultFuture<(), anyhow::Error> {
        let filter_controller = self.0.clone();
        Box::pin(async move {
            if let TaskContent::Text(predicate) = content {
                let _ = filter_controller
                    .read()
                    .await
                    .process(&predicate)
                    .await
                    .map_err(anyhow::Error::from);
            }
            Ok(())
        })
    }
}
