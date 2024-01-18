use std::str::FromStr;
use std::sync::Arc;

use collab_database::rows::RowCell;
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

use flowy_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use lib_infra::future::Fut;

use crate::services::calculations::CalculationsCache;
use crate::services::database_view::DatabaseViewChangedNotifier;

pub trait CalculationsDelegate: Send + Sync + 'static {
  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>>;
}

pub struct CalculationsController {
  view_id: String,
  handler_id: String,
  delegate: Box<dyn CalculationsDelegate>,
  calculations_cache: CalculationsCache,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  notifier: DatabaseViewChangedNotifier,
}

impl Drop for CalculationsController {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl CalculationsController {
  pub async fn new<T>(
    view_id: &str,
    handler_id: &str,
    delegate: T,
    // calculations: Vec<Arc<Calculation>>,
    calculations_cache: CalculationsCache,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    notifier: DatabaseViewChangedNotifier,
  ) -> Self
  where
    T: CalculationsDelegate + 'static,
  {
    let this = Self {
      view_id: view_id.to_string(),
      handler_id: handler_id.to_string(),
      delegate: Box::new(delegate),
      calculations_cache,
      task_scheduler,
      notifier,
    };
    this
  }

  pub async fn close(&self) {
    if let Ok(mut task_scheduler) = self.task_scheduler.try_write() {
      task_scheduler.unregister_handler(&self.handler_id).await;
    } else {
      tracing::error!("Try to get the lock of task_scheduler failed");
    }
  }

  #[tracing::instrument(name = "schedule_filter_task", level = "trace", skip(self))]
  async fn gen_task(&self, task_type: CalculationEvent, qos: QualityOfService) {
    let task_id = self.task_scheduler.read().await.next_task_id();
    let task = Task::new(
      &self.handler_id,
      task_id,
      TaskContent::Text(task_type.to_string()),
      qos,
    );
    self.task_scheduler.write().await.add_task(task);
  }

  #[tracing::instrument(
    name = "process_filter_task",
    level = "trace",
    skip_all,
    fields(filter_result),
    err
  )]
  pub async fn process(&self, predicate: &str) -> FlowyResult<()> {
    let event_type = CalculationEvent::from_str(predicate).unwrap();
    match event_type {
      CalculationEvent::CellDidChange => self.update_calculations().await?,
    }
    Ok(())
  }

  async fn update_calculations(&self) -> FlowyResult<()> {
    todo!("Update Calculations");
  }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
enum CalculationEvent {
  CellDidChange,
}

impl ToString for CalculationEvent {
  fn to_string(&self) -> String {
    serde_json::to_string(self).unwrap()
  }
}

impl FromStr for CalculationEvent {
  type Err = serde_json::Error;
  fn from_str(s: &str) -> Result<Self, Self::Err> {
    serde_json::from_str(s)
  }
}
