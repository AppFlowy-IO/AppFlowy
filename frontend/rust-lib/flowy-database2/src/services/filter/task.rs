use crate::services::filter::FilterController;
use async_trait::async_trait;

use lib_infra::priority_task::{TaskContent, TaskHandler};
use std::sync::Arc;

pub struct FilterTaskHandler {
  handler_id: String,
  filter_controller: Arc<FilterController>,
}

impl FilterTaskHandler {
  pub fn new(handler_id: String, filter_controller: Arc<FilterController>) -> Self {
    Self {
      handler_id,
      filter_controller,
    }
  }
}

#[async_trait]
impl TaskHandler for FilterTaskHandler {
  fn handler_id(&self) -> &str {
    &self.handler_id
  }

  fn handler_name(&self) -> &str {
    "FilterTaskHandler"
  }

  async fn run(&self, content: TaskContent) -> Result<(), anyhow::Error> {
    let filter_controller = self.filter_controller.clone();
    if let TaskContent::Text(predicate) = content {
      filter_controller
        .process(&predicate)
        .await
        .map_err(anyhow::Error::from)?;
    }
    Ok(())
  }
}
