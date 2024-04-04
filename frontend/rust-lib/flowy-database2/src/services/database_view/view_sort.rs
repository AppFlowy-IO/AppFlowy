use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::RowDetail;
use tokio::sync::RwLock;

use lib_infra::future::{to_fut, Fut};

use crate::services::cell::CellCache;
use crate::services::database_view::{
  gen_handler_id, DatabaseViewChangedNotifier, DatabaseViewOperation,
};
use crate::services::filter::FilterController;
use crate::services::sort::{Sort, SortController, SortDelegate, SortTaskHandler};

pub(crate) async fn make_sort_controller(
  view_id: &str,
  delegate: Arc<dyn DatabaseViewOperation>,
  notifier: DatabaseViewChangedNotifier,
  filter_controller: Arc<FilterController>,
  cell_cache: CellCache,
) -> Arc<RwLock<SortController>> {
  let handler_id = gen_handler_id();
  let sorts = delegate
    .get_all_sorts(view_id)
    .into_iter()
    .map(Arc::new)
    .collect();
  let task_scheduler = delegate.get_task_scheduler();
  let sort_delegate = DatabaseViewSortDelegateImpl {
    delegate,
    filter_controller,
  };
  let sort_controller = Arc::new(RwLock::new(SortController::new(
    view_id,
    &handler_id,
    sorts,
    sort_delegate,
    task_scheduler.clone(),
    cell_cache,
    notifier,
  )));
  task_scheduler
    .write()
    .await
    .register_handler(SortTaskHandler::new(handler_id, sort_controller.clone()));

  sort_controller
}

struct DatabaseViewSortDelegateImpl {
  delegate: Arc<dyn DatabaseViewOperation>,
  filter_controller: Arc<FilterController>,
}

impl SortDelegate for DatabaseViewSortDelegateImpl {
  fn get_sort(&self, view_id: &str, sort_id: &str) -> Fut<Option<Arc<Sort>>> {
    let sort = self.delegate.get_sort(view_id, sort_id).map(Arc::new);
    to_fut(async move { sort })
  }

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<RowDetail>>> {
    let view_id = view_id.to_string();
    let delegate = self.delegate.clone();
    let filter_controller = self.filter_controller.clone();
    to_fut(async move {
      let mut row_details = delegate.get_rows(&view_id).await;
      filter_controller.filter_rows(&mut row_details).await;
      row_details
    })
  }

  fn filter_row(&self, row_detail: &RowDetail) -> Fut<bool> {
    let filter_controller = self.filter_controller.clone();
    let row_detail = row_detail.clone();
    to_fut(async move {
      let mut row_details = vec![Arc::new(row_detail)];
      filter_controller.filter_rows(&mut row_details).await;
      !row_details.is_empty()
    })
  }

  fn get_field(&self, field_id: &str) -> Option<Field> {
    self.delegate.get_field(field_id)
  }

  fn get_fields(&self, view_id: &str, field_ids: Option<Vec<String>>) -> Fut<Vec<Field>> {
    self.delegate.get_fields(view_id, field_ids)
  }
}
