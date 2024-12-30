use crate::services::calculations::CalculationsController;
use async_trait::async_trait;

use lib_infra::priority_task::{TaskContent, TaskHandler};
use std::sync::Arc;

pub struct CalculationsTaskHandler {
  handler_id: String,
  calculations_controller: Arc<CalculationsController>,
}

impl CalculationsTaskHandler {
  pub fn new(handler_id: String, calculations_controller: Arc<CalculationsController>) -> Self {
    Self {
      handler_id,
      calculations_controller,
    }
  }
}

#[async_trait]
impl TaskHandler for CalculationsTaskHandler {
  fn handler_id(&self) -> &str {
    &self.handler_id
  }

  fn handler_name(&self) -> &str {
    "CalculationsTaskHandler"
  }

  async fn run(&self, content: TaskContent) -> Result<(), anyhow::Error> {
    let calculations_controller = self.calculations_controller.clone();
    if let TaskContent::Text(predicate) = content {
      calculations_controller
        .process(&predicate)
        .await
        .map_err(anyhow::Error::from)?;
    }
    Ok(())
  }
}
