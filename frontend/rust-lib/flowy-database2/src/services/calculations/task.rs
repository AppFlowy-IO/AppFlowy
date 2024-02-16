use lib_infra::future::BoxResultFuture;
use lib_infra::priority_task::{TaskContent, TaskHandler};
use std::sync::Arc;

use crate::services::calculations::CalculationsController;

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

impl TaskHandler for CalculationsTaskHandler {
  fn handler_id(&self) -> &str {
    &self.handler_id
  }

  fn handler_name(&self) -> &str {
    "CalculationsTaskHandler"
  }

  fn run(&self, content: TaskContent) -> BoxResultFuture<(), anyhow::Error> {
    let calculations_controller = self.calculations_controller.clone();
    Box::pin(async move {
      if let TaskContent::Text(predicate) = content {
        calculations_controller
          .process(&predicate)
          .await
          .map_err(anyhow::Error::from)?;
      }
      Ok(())
    })
  }
}
