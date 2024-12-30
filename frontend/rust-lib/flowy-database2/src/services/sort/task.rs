use crate::services::sort::SortController;
use async_trait::async_trait;

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

#[async_trait]
impl TaskHandler for SortTaskHandler {
  fn handler_id(&self) -> &str {
    &self.handler_id
  }

  fn handler_name(&self) -> &str {
    "SortTaskHandler"
  }

  async fn run(&self, content: TaskContent) -> Result<(), anyhow::Error> {
    let sort_controller = self.sort_controller.clone();
    if let TaskContent::Text(predicate) = content {
      sort_controller
        .write()
        .await
        .process(&predicate)
        .await
        .map_err(anyhow::Error::from)?;
    }
    Ok(())
  }
}
