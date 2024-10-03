use async_trait::async_trait;
use std::str::FromStr;
use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{Cell, Row, RowCell};
use dashmap::DashMap;
use flowy_error::FlowyResult;
use lib_infra::priority_task::{QualityOfService, Task, TaskContent, TaskDispatcher};
use serde::{Deserialize, Serialize};
use tokio::sync::RwLock as TokioRwLock;
use tracing::instrument;

use crate::entities::{
  CalculationChangesetNotificationPB, CalculationPB, CalculationType, FieldType,
};
use crate::services::calculations::CalculationsByFieldIdCache;
use crate::services::database_view::{DatabaseViewChanged, DatabaseViewChangedNotifier};
use crate::utils::cache::AnyTypeCache;

use super::{Calculation, CalculationChangeset, CalculationsService};

#[async_trait]
pub trait CalculationsDelegate: Send + Sync + 'static {
  async fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Vec<Arc<Cell>>;
  async fn get_field(&self, field_id: &str) -> Option<Field>;
  async fn get_calculation(&self, view_id: &str, field_id: &str) -> Option<Arc<Calculation>>;
  async fn get_all_calculations(&self, view_id: &str) -> Vec<Arc<Calculation>>;
  async fn update_calculation(&self, view_id: &str, calculation: Calculation);
  async fn remove_calculation(&self, view_id: &str, calculation_id: &str);
}

pub struct CalculationsController {
  view_id: String,
  handler_id: String,
  delegate: Box<dyn CalculationsDelegate>,
  calculations_by_field_cache: CalculationsByFieldIdCache,
  task_scheduler: Arc<TokioRwLock<TaskDispatcher>>,
  calculations_service: CalculationsService,
  notifier: DatabaseViewChangedNotifier,
}

impl Drop for CalculationsController {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl CalculationsController {
  pub fn new<T>(
    view_id: &str,
    handler_id: &str,
    delegate: T,
    calculations: Vec<Arc<Calculation>>,
    task_scheduler: Arc<TokioRwLock<TaskDispatcher>>,
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
    this.update_cache(calculations);
    this
  }

  pub async fn close(&self) {
    self
      .task_scheduler
      .write()
      .await
      .unregister_handler(&self.handler_id)
      .await;
  }

  #[tracing::instrument(name = "schedule_calculation_task", level = "trace", skip(self))]
  pub(crate) async fn gen_task(&self, task_type: CalculationEvent, qos: QualityOfService) {
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
    name = "process_calculation_task",
    level = "trace",
    skip_all,
    fields(calculation_result),
    err
  )]
  pub async fn process(&self, predicate: &str) -> FlowyResult<()> {
    let event_type = CalculationEvent::from_str(predicate).unwrap();
    match event_type {
      CalculationEvent::RowChanged(row) => self.handle_row_changed(&row).await,
      CalculationEvent::CellUpdated(field_id) => self.handle_cell_changed(field_id).await,
      CalculationEvent::FieldDeleted(field_id) => self.handle_field_deleted(field_id).await,
      CalculationEvent::FieldTypeChanged(field_id, new_field_type) => {
        self
          .handle_field_type_changed(field_id, new_field_type)
          .await
      },
      CalculationEvent::InitialRows(rows) => {
        for row in rows {
          self.handle_row_changed(row.as_ref()).await;
        }
      },
    }

    Ok(())
  }

  pub async fn did_receive_field_deleted(&self, field_id: String) {
    self
      .gen_task(
        CalculationEvent::FieldDeleted(field_id),
        QualityOfService::Background,
      )
      .await
  }

  async fn handle_field_deleted(&self, field_id: String) {
    let calculation = self
      .delegate
      .get_calculation(&self.view_id, &field_id)
      .await;

    if let Some(calculation) = calculation {
      self
        .delegate
        .remove_calculation(&self.view_id, &calculation.id)
        .await;

      let notification = CalculationChangesetNotificationPB::from_delete(
        &self.view_id,
        vec![CalculationPB::from(&calculation)],
      );

      let _ = self
        .notifier
        .send(DatabaseViewChanged::CalculationValueNotification(
          notification,
        ));
    }
  }

  pub async fn did_receive_field_type_changed(&self, field_id: String, new_field_type: FieldType) {
    self
      .gen_task(
        CalculationEvent::FieldTypeChanged(field_id, new_field_type),
        QualityOfService::Background,
      )
      .await
  }

  async fn handle_field_type_changed(&self, field_id: String, new_field_type: FieldType) {
    let calculation = self
      .delegate
      .get_calculation(&self.view_id, &field_id)
      .await;

    if let Some(calculation) = calculation {
      let calc_type: CalculationType = calculation.calculation_type.into();
      if !calc_type.is_allowed(new_field_type) {
        self
          .delegate
          .remove_calculation(&self.view_id, &calculation.id)
          .await;

        let notification = CalculationChangesetNotificationPB::from_delete(
          &self.view_id,
          vec![CalculationPB::from(&calculation)],
        );

        let _ = self
          .notifier
          .send(DatabaseViewChanged::CalculationValueNotification(
            notification,
          ));
      }
    }
  }

  pub async fn did_receive_cell_changed(&self, field_id: String) {
    self
      .gen_task(
        CalculationEvent::CellUpdated(field_id),
        QualityOfService::Background,
      )
      .await
  }

  async fn handle_cell_changed(&self, field_id: String) {
    let calculation = self
      .delegate
      .get_calculation(&self.view_id, &field_id)
      .await;

    if let Some(calculation) = calculation {
      if let Some(field) = self.delegate.get_field(&field_id).await {
        let cells = self
          .delegate
          .get_cells_for_field(&self.view_id, &calculation.field_id)
          .await;

        // Update the calculation
        if let Some(update) = self.update_calculation(calculation, &field, cells).await {
          self
            .delegate
            .update_calculation(&self.view_id, update.clone())
            .await;

          // Send notification
          let notification = CalculationChangesetNotificationPB::from_update(
            &self.view_id,
            vec![CalculationPB::from(&update)],
          );

          let _ = self
            .notifier
            .send(DatabaseViewChanged::CalculationValueNotification(
              notification,
            ));
        }
      }
    }
  }

  pub async fn did_receive_row_changed(&self, row: Row) {
    self
      .gen_task(
        CalculationEvent::RowChanged(row),
        QualityOfService::Background,
      )
      .await
  }

  async fn handle_row_changed(&self, row: &Row) {
    let cells = &row.cells;
    let mut updates = vec![];
    let mut cells_by_field = DashMap::<String, Vec<Arc<Cell>>>::new();

    // In case there are calculations where empty cells are counted
    // as a contribution to the value.
    if cells.len() == 0 {
      let calculations = self.delegate.get_all_calculations(&self.view_id).await;
      for calculation in calculations.into_iter() {
        let cells = self
          .get_or_fetch_cells(&calculation.field_id, &mut cells_by_field)
          .await;
        updates.extend(self.handle_cells_changed(calculation, cells).await);
      }
    }

    // Iterate each cell in the row
    for cell in cells {
      let field_id = &cell.0;
      let calculation = self.delegate.get_calculation(&self.view_id, field_id).await;
      if let Some(calculation) = calculation {
        let cells = self
          .get_or_fetch_cells(&calculation.field_id, &mut cells_by_field)
          .await;
        let changes = self.handle_cells_changed(calculation, cells).await;
        updates.extend(changes);
      }
    }

    if !updates.is_empty() {
      let notification = CalculationChangesetNotificationPB::from_update(&self.view_id, updates);
      let _ = self
        .notifier
        .send(DatabaseViewChanged::CalculationValueNotification(
          notification,
        ));
    }
  }

  async fn get_or_fetch_cells<'a>(
    &'a self,
    field_id: &'a str,
    cells_by_field: &'a mut DashMap<String, Vec<Arc<Cell>>>,
  ) -> Vec<Arc<Cell>> {
    let mut cells = cells_by_field.get(field_id).map(|entry| entry.to_vec());
    match cells {
      None => {
        let fetch_cells = self
          .delegate
          .get_cells_for_field(&self.view_id, field_id)
          .await;
        cells_by_field.insert(field_id.to_string(), fetch_cells.clone());
        fetch_cells
      },
      Some(cells) => cells,
    }
  }

  /// field_cells will be the cells that belong to the field with field_id
  async fn handle_cells_changed(
    &self,
    calculation: Arc<Calculation>,
    field_cells: Vec<Arc<Cell>>,
  ) -> Vec<CalculationPB> {
    let mut updates = vec![];
    if let Some(field) = self.delegate.get_field(&calculation.field_id).await {
      let update = self
        .update_calculation(calculation, &field, field_cells)
        .await;
      if let Some(update) = update {
        updates.push(CalculationPB::from(&update));
        self
          .delegate
          .update_calculation(&self.view_id, update)
          .await;
      }
    }

    updates
  }

  #[instrument(level = "trace", skip_all)]
  async fn update_calculation(
    &self,
    calculation: Arc<Calculation>,
    field: &Field,
    cells: Vec<Arc<Cell>>,
  ) -> Option<Calculation> {
    let value = self
      .calculations_service
      .calculate(&field, calculation.calculation_type, cells);

    if value != calculation.value {
      return Some(calculation.with_value(value));
    }

    None
  }

  pub async fn did_receive_changes(
    &self,
    changeset: CalculationChangeset,
  ) -> Option<CalculationChangesetNotificationPB> {
    let mut notification: Option<CalculationChangesetNotificationPB> = None;

    if let Some(insert) = &changeset.insert_calculation {
      let cells = self
        .delegate
        .get_cells_for_field(&self.view_id, &insert.field_id)
        .await;

      let field = self.delegate.get_field(&insert.field_id).await?;

      let value = self
        .calculations_service
        .calculate(&field, insert.calculation_type, cells);

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

  fn update_cache(&self, calculations: Vec<Arc<Calculation>>) {
    for calculation in calculations {
      let field_id = &calculation.field_id;
      self
        .calculations_by_field_cache
        .insert(field_id, calculation.clone());
    }
  }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub(crate) enum CalculationEvent {
  InitialRows(Vec<Arc<Row>>),
  RowChanged(Row),
  CellUpdated(String),
  FieldTypeChanged(String, FieldType),
  FieldDeleted(String),
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
