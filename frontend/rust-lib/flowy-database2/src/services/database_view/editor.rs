use crate::entities::{CreateRowParams, FieldType, RowsChangesetPB};
use crate::notification::{send_notification, DatabaseNotification};
use crate::services::database::DatabaseRowEvent;
use crate::services::database_view::DatabaseViewChangedNotifier;
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::filter::FilterController;
use crate::services::group::GroupController;
use crate::services::sort::SortController;
use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use flowy_error::FlowyResult;
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;
use std::borrow::Cow;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DatabaseViewData: Send + Sync + 'static {
  /// If the field_ids is None, then it will return all the field revisions
  fn get_fields(&self, field_ids: Option<Vec<String>>) -> Fut<Vec<Arc<Field>>>;

  /// Returns the field with the field_id
  fn get_field(&self, field_id: &str) -> Fut<Option<Arc<Field>>>;

  fn get_primary_field(&self) -> Fut<Option<Arc<Field>>>;

  /// Returns the index of the row with row_id
  fn index_of_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<usize>>;

  /// Returns the `index` and `RowRevision` with row_id
  fn get_row(&self, view_id: &str, row_id: RowId) -> Fut<Option<(usize, Arc<Row>)>>;

  fn get_rows(&self, view_id: &str) -> Fut<Vec<Arc<Row>>>;

  /// Returns a `TaskDispatcher` used to poll a `Task`
  fn get_task_scheduler(&self) -> Arc<RwLock<TaskDispatcher>>;

  fn get_type_option_cell_handler(
    &self,
    field: &Field,
    field_type: &FieldType,
  ) -> Option<Box<dyn TypeOptionCellDataHandler>>;
}

pub struct DatabaseViewEditor {
  pub view_id: String,
  delegate: Arc<dyn DatabaseViewData>,
  group_controller: Arc<RwLock<Box<dyn GroupController>>>,
  filter_controller: Arc<FilterController>,
  sort_controller: Arc<RwLock<SortController>>,
  pub notifier: DatabaseViewChangedNotifier,
}

impl Drop for DatabaseViewEditor {
  fn drop(&mut self) {
    tracing::trace!("Drop {}", std::any::type_name::<Self>());
  }
}

impl DatabaseViewEditor {
  pub async fn v_will_create_row(&self, row: &mut Row, params: CreateRowParams) {
    if params.group_id.is_none() {
      return;
    }
    let group_id = params.group_id.as_ref().unwrap();
    let _ = self
      .mut_group_controller(|group_controller, field| {
        group_controller.will_create_row(row, &field, group_id);
        Ok(())
      })
      .await;
  }

  pub async fn handle_block_event(&self, event: Cow<'_, DatabaseRowEvent>) {
    let changeset = match event.into_owned() {
      DatabaseRowEvent::InsertRow { row } => {
        RowsChangesetPB::from_insert(self.view_id.clone(), vec![row.into()])
      },
      DatabaseRowEvent::UpdateRow { row } => {
        RowsChangesetPB::from_update(self.view_id.clone(), vec![row.into()])
      },
      DatabaseRowEvent::DeleteRow { row_id } => {
        RowsChangesetPB::from_delete(self.view_id.clone(), vec![row_id])
      },
      DatabaseRowEvent::Move {
        deleted_row_id,
        inserted_row,
      } => RowsChangesetPB::from_move(
        self.view_id.clone(),
        vec![deleted_row_id],
        vec![inserted_row.into()],
      ),
    };

    send_notification(&self.view_id, DatabaseNotification::DidUpdateViewRows)
      .payload(changeset)
      .send();
  }

  async fn mut_group_controller<F, T>(&self, f: F) -> Option<T>
  where
    F: FnOnce(&mut Box<dyn GroupController>, Arc<Field>) -> FlowyResult<T>,
  {
    let group_field_id = self.group_controller.read().await.field_id().to_owned();
    match self.delegate.get_field(&group_field_id).await {
      None => None,
      Some(field) => {
        let mut write_guard = self.group_controller.write().await;
        f(&mut write_guard, field).ok()
      },
    }
  }
}
