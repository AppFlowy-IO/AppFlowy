use async_trait::async_trait;
use collab_database::fields::Field;
use std::sync::Arc;

use collab_database::rows::RowCell;

use crate::services::calculations::{
  Calculation, CalculationsController, CalculationsDelegate, CalculationsTaskHandler,
};

use crate::services::database_view::{
  gen_handler_id, DatabaseViewChangedNotifier, DatabaseViewOperation,
};

pub async fn make_calculations_controller(
  view_id: &str,
  delegate: Arc<dyn DatabaseViewOperation>,
  notifier: DatabaseViewChangedNotifier,
) -> Arc<CalculationsController> {
  let calculations = delegate.get_all_calculations(view_id).await;
  let task_scheduler = delegate.get_task_scheduler();
  let calculations_delegate = DatabaseViewCalculationsDelegateImpl(delegate.clone());
  let handler_id = gen_handler_id();

  let calculations_controller = CalculationsController::new(
    view_id,
    &handler_id,
    calculations_delegate,
    calculations,
    task_scheduler.clone(),
    notifier,
  );

  let calculations_controller = Arc::new(calculations_controller);
  task_scheduler
    .write()
    .await
    .register_handler(CalculationsTaskHandler::new(
      handler_id,
      calculations_controller.clone(),
    ));
  calculations_controller
}

struct DatabaseViewCalculationsDelegateImpl(Arc<dyn DatabaseViewOperation>);

#[async_trait]
impl CalculationsDelegate for DatabaseViewCalculationsDelegateImpl {
  async fn get_cells_for_field(&self, view_id: &str, field_id: &str) -> Vec<Arc<RowCell>> {
    self.0.get_cells_for_field(view_id, field_id).await
  }

  async fn get_field(&self, field_id: &str) -> Option<Field> {
    self.0.get_field(field_id).await
  }

  async fn get_calculation(&self, view_id: &str, field_id: &str) -> Option<Arc<Calculation>> {
    self
      .0
      .get_calculation(view_id, field_id)
      .await
      .map(Arc::new)
  }

  async fn update_calculation(&self, view_id: &str, calculation: Calculation) {
    self.0.update_calculation(view_id, calculation).await
  }

  async fn remove_calculation(&self, view_id: &str, calculation_id: &str) {
    self.0.remove_calculation(view_id, calculation_id).await
  }

  async fn get_all_calculations(&self, view_id: &str) -> Vec<Arc<Calculation>> {
    self.0.get_all_calculations(view_id).await
  }
}
