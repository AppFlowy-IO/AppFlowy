use std::str::FromStr;
use std::sync::Arc;

use collab_database::rows::{RowCell, RowDetail, RowId};
use flowy_error::FlowyResult;
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock;

use lib_infra::future::Fut;
use lib_infra::priority_task::{QualityOfService, Task, TaskContent, TaskDispatcher};

use crate::entities::{CalculationChangesetNotificationPB, CalculationPB, CalculationType};
use crate::services::calculations::CalculationsByFieldIdCache;
use crate::services::database_view::DatabaseViewChangedNotifier;
use crate::utils::cache::AnyTypeCache;

use super::{Calculation, CalculationChangeset, CalculationsService};

pub trait CalculationsDelegate: Send + Sync + 'static {
  fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Fut<Vec<Arc<RowCell>>>;

  fn get_row(&self, view_id: &str, row_id: &RowId) -> Fut<Option<(usize, Arc<RowDetail>)>>;
}

pub struct CalculationsController {
  view_id: String,
  handler_id: String,
  delegate: Box<dyn CalculationsDelegate>,
  calculations_by_field_cache: CalculationsByFieldIdCache,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  calculations_service: CalculationsService,
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
    calculations: Vec<Arc<Calculation>>,
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
      calculations_by_field_cache: AnyTypeCache::<String>::new(),
      task_scheduler,
      calculations_service: CalculationsService::new(),
      notifier,
    };
    this.update_cache(calculations).await;
    this
  }

  pub async fn close(&self) {
    if let Ok(mut task_scheduler) = self.task_scheduler.try_write() {
      task_scheduler.unregister_handler(&self.handler_id).await;
    } else {
      tracing::error!("Attempt to get the lock of task_scheduler failed");
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
      CalculationEvent::RowDeleted(row_id) => self.update_calculation(row_id).await?,
    }
    Ok(())
  }

  pub async fn did_receive_row_changed(&self, _row_id: RowId) {
    todo!("RowDeleted / CellChanged")
    // let row = self.delegate.get_row(&self.view_id, &row_id.clone()).await;

    // self
    //   .gen_task(
    //     CalculationEvent::RowDeleted(row_id.into_inner()),
    //     QualityOfService::UserInteractive,
    //   )
    //   .await
  }

  pub async fn did_receive_changes(
    &self,
    changeset: CalculationChangeset,
  ) -> Option<CalculationChangesetNotificationPB> {
    let mut notification: Option<CalculationChangesetNotificationPB> = None;

    if let Some(insert) = &changeset.insert_calculation {
      let row_cells: Vec<Arc<RowCell>> = self
        .delegate
        .get_cells_for_field(&self.view_id, &insert.field_id)
        .await;

      let value = self
        .calculations_service
        .calculate(insert.calculation_type, row_cells);

      notification = Some(CalculationChangesetNotificationPB::from_insert(
        &self.view_id,
        vec![CalculationPB {
          id: insert.id.clone(),
          field_id: insert.field_id.clone(),
          calculation_type: CalculationType::from(insert.calculation_type),
          value,
        }],
      ))
    }

    if let Some(delete) = &changeset.delete_calculation {
      notification = Some(CalculationChangesetNotificationPB::from_delete(
        &self.view_id,
        vec![CalculationPB {
          id: delete.id.clone(),
          field_id: delete.field_id.clone(),
          calculation_type: CalculationType::from(delete.calculation_type),
          value: delete.value.clone(),
        }],
      ))
    }

    notification
  }

  async fn update_cache(&self, calculations: Vec<Arc<Calculation>>) {
    for calculation in calculations {
      let field_id = &calculation.field_id;
      self
        .calculations_by_field_cache
        .write()
        .insert(field_id, calculation.clone());
    }
  }

  async fn update_calculation(&self, _row_id: String) -> FlowyResult<()> {
    todo!("update_calculation");
  }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
enum CalculationEvent {
  RowDeleted(String),
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
