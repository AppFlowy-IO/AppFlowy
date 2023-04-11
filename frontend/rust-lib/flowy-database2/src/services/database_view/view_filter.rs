use crate::services::cell::CellCache;
use crate::services::database_view::{
  gen_handler_id, DatabaseViewChangedNotifier, DatabaseViewData,
};
use crate::services::filter::{
  Filter, FilterController, FilterDelegate, FilterTaskHandler, FilterType,
};
use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use lib_infra::future::Fut;
use std::sync::Arc;

pub async fn make_filter_controller(
  view_id: &str,
  delegate: Arc<dyn DatabaseViewData>,
  notifier: DatabaseViewChangedNotifier,
  cell_cache: CellCache,
) -> Arc<FilterController> {
  let filters = delegate.get_all_filters(view_id);
  let task_scheduler = delegate.get_task_scheduler();
  let filter_delegate = DatabaseViewFilterDelegateImpl(delegate.clone());

  let handler_id = gen_handler_id();
  let filter_controller = FilterController::new(
    view_id,
    &handler_id,
    filter_delegate,
    task_scheduler.clone(),
    filters,
    cell_cache,
    notifier,
  )
  .await;
  let filter_controller = Arc::new(filter_controller);
  task_scheduler
    .write()
    .await
    .register_handler(FilterTaskHandler::new(
      handler_id,
      filter_controller.clone(),
    ));
  filter_controller
}

struct DatabaseViewFilterDelegateImpl(Arc<dyn DatabaseViewData>);

impl FilterDelegate for DatabaseViewFilterDelegateImpl {
  fn get_filter(&self, filter_type: FilterType) -> Fut<Option<Arc<Filter>>> {
    todo!()
  }

  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>> {
    todo!()
  }

  fn get_fields(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>> {
    todo!()
  }

  fn get_rows(&self) -> Fut<Vec<Row>> {
    todo!()
  }

  fn get_row(&self, rows_id: RowId) -> Fut<Option<(usize, Arc<Row>)>> {
    todo!()
  }
}
