use crate::services::filter::FilterController;
use flowy_task::{TaskContent, TaskHandler};
use lib_infra::future::BoxResultFuture;
use std::collections::HashMap;
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

impl TaskHandler for FilterTaskHandler {
  fn handler_id(&self) -> &str {
    &self.handler_id
  }

  fn handler_name(&self) -> &str {
    "FilterTaskHandler"
  }

  fn run(&self, content: TaskContent) -> BoxResultFuture<(), anyhow::Error> {
    let filter_controller = self.filter_controller.clone();
    Box::pin(async move {
      if let TaskContent::Text(predicate) = content {
        filter_controller
          .process(&predicate)
          .await
          .map_err(anyhow::Error::from)?;
      }
      Ok(())
    })
  }
}
/// Refresh the filter according to the field id.
#[derive(Default)]
pub(crate) struct FilterResult {
  pub(crate) visible_by_field_id: HashMap<String, bool>,
}

impl FilterResult {
  pub(crate) fn is_visible(&self) -> bool {
    let mut is_visible = true;
    for visible in self.visible_by_field_id.values() {
      if !is_visible {
        break;
      }
      is_visible = *visible;
    }
    is_visible
  }
}
