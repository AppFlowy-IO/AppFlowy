use crate::entities::{DeleteGroupParams, FieldType, InsertGroupParams, MoveGroupParams};
use crate::manager::DatabaseUser2;
use crate::services::cell::CellCache;
use crate::services::database::{Database, DatabaseRowEvent};
use crate::services::database_view::{
  DatabaseViewChangedNotifier, DatabaseViewData, DatabaseViewEditor,
};
use crate::services::field::TypeOptionCellDataHandler;
use crate::services::group::{default_group_setting, RowChangeset};
use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use flowy_error::FlowyResult;
use flowy_task::TaskDispatcher;
use lib_infra::future::{to_fut, Fut};
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub type RowEventSender = broadcast::Sender<DatabaseRowEvent>;
pub type RowEventReceiver = broadcast::Receiver<DatabaseRowEvent>;

pub struct DatabaseViews {
  database: Database,
  cell_cache: CellCache,
  database_view_data: Arc<dyn DatabaseViewData>,
  editor_map: Arc<RwLock<HashMap<String, Arc<DatabaseViewEditor>>>>,
}

impl DatabaseViews {
  pub async fn new(
    database: Database,
    cell_cache: CellCache,
    database_view_data: Arc<dyn DatabaseViewData>,
    row_event_rx: RowEventReceiver,
  ) -> FlowyResult<Self> {
    let editor_map = Arc::new(RwLock::new(HashMap::default()));
    listen_on_database_row_event(row_event_rx, editor_map.clone());
    Ok(Self {
      database,
      database_view_data,
      cell_cache,
      editor_map,
    })
  }

  pub async fn open_view(&self, view: DatabaseViewEditor) {
    self
      .editor_map
      .write()
      .await
      .insert(view.view_id.clone(), Arc::new(view));
  }

  pub async fn close_view(&self, view_id: &str) {
    self.editor_map.write().await.remove(view_id);
  }

  pub async fn insert_or_update_group(&self, params: InsertGroupParams) -> FlowyResult<()> {
    if let Some(field) = self.database.lock().fields.get_field(&params.field_id) {
      let group_setting = default_group_setting(&field);
      self
        .database
        .lock()
        .add_group_setting(&params.view_id, group_setting);
    }

    if let Some(view_editor) = self.editor_map.read().await.get(&params.view_id) {
      view_editor.v_initialize_new_group(params).await?;
    }
    Ok(())
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .delete_group_setting(&params.view_id, &params.group_id);
    if let Some(view_editor) = self.editor_map.read().await.get(&params.view_id) {
      view_editor.v_delete_group(params).await?;
    }
    Ok(())
  }

  pub async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
    if let Some(view_editor) = self.editor_map.read().await.get(&params.view_id) {
      view_editor.v_move_group(params).await?;
    }
    Ok(())
  }

  /// It may generate a RowChangeset when the Row was moved from one group to another.
  /// The return value, [RowChangeset], contains the changes made by the groups.
  ///
  pub async fn move_group_row(
    &self,
    view_id: &str,
    row: Arc<Row>,
    to_group_id: String,
    to_row_id: Option<RowId>,
    recv_row_changeset: impl FnOnce(RowChangeset) -> Fut<()>,
  ) -> FlowyResult<()> {
    if let Some(view_editor) = self.editor_map.read().await.get(view_id) {
      let mut row_changeset = RowChangeset::new(row.id.clone());
      view_editor
        .v_move_group_row(
          &row_rev,
          &mut row_changeset,
          &to_group_id,
          to_row_id.clone(),
        )
        .await?;

      if !row_changeset.is_empty() {
        recv_row_changeset(row_changeset).await;
      }
    }

    Ok(())
  }

  pub async fn subscribe_view_changed(&self, view_id: &str) -> DatabaseViewChangedNotifier {
    let read_guard = self.editor_map.read().await;
    let view_editor = read_guard.get(view_id).unwrap();
    view_editor.notifier.clone()
  }
}

fn listen_on_database_row_event(
  mut row_event_rx: broadcast::Receiver<DatabaseRowEvent>,
  view_editors: Arc<RwLock<HashMap<String, Arc<DatabaseViewEditor>>>>,
) {
  tokio::spawn(async move {
    loop {
      match row_event_rx.recv().await {
        Ok(event) => {
          let read_guard = view_editors.read().await;
          let view_editors = read_guard.values();
          let event = if view_editors.len() == 1 {
            Cow::Owned(event)
          } else {
            Cow::Borrowed(&event)
          };
          for view_editor in view_editors {
            view_editor.handle_block_event(event.clone()).await;
          }
        },
        Err(_) => break,
      }
    }
  });
}
