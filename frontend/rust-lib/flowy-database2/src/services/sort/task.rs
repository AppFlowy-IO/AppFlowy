use crate::services::sort::SortController;
use lib_infra::future::BoxResultFuture;
use lib_infra::priority_task::{TaskContent, TaskHandler};
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

  fn handler_name(&self) -> &str {
    "SortTaskHandler"
  }

  fn run(&self, content: TaskContent) -> BoxResultFuture<(), anyhow::Error> {
    let sort_controller = self.sort_controller.clone();
    Box::pin(async move {
      if let TaskContent::Text(predicate) = content {
        sort_controller
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
