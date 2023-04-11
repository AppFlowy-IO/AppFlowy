use crate::entities::{DeleteGroupParams, InsertGroupParams, MoveGroupParams};
use crate::services::cell::CellCache;
use crate::services::database::{DatabaseRowEvent, MutexDatabase};
use crate::services::database_view::{DatabaseViewData, DatabaseViewEditor};
use crate::services::group::{default_group_setting, RowChangeset};
use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use flowy_error::FlowyResult;
use lib_infra::future::Fut;
use nanoid::nanoid;
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub type RowEventSender = broadcast::Sender<DatabaseRowEvent>;
pub type RowEventReceiver = broadcast::Receiver<DatabaseRowEvent>;

pub struct DatabaseViews {
  database: MutexDatabase,
  cell_cache: CellCache,
  database_view_data: Arc<dyn DatabaseViewData>,
  editor_map: Arc<RwLock<HashMap<String, Arc<DatabaseViewEditor>>>>,
}

impl DatabaseViews {
  pub async fn new(
    database: MutexDatabase,
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
        .insert_group_setting(&params.view_id, group_setting);
    }
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_initialize_new_group(params).await?;

    Ok(())
  }

  pub async fn delete_group(&self, params: DeleteGroupParams) -> FlowyResult<()> {
    self
      .database
      .lock()
      .delete_group_setting(&params.view_id, &params.group_id);
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_delete_group(params).await?;
    Ok(())
  }

  pub async fn move_group(&self, params: MoveGroupParams) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(&params.view_id).await?;
    view_editor.v_move_group(params).await?;
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
    let view_editor = self.get_view_editor(view_id).await?;
    let mut row_changeset = RowChangeset::new(row.id.clone());
    view_editor
      .v_move_group_row(&row, &mut row_changeset, &to_group_id, to_row_id.clone())
      .await;

    if !row_changeset.is_empty() {
      recv_row_changeset(row_changeset).await;
    }

    Ok(())
  }

  /// Notifies the view's field type-option data is changed
  /// For the moment, only the groups will be generated after the type-option data changed. A
  /// [Field] has a property named type_options contains a list of type-option data.
  /// # Arguments
  ///
  /// * `field_id`: the id of the field in current view
  ///
  #[tracing::instrument(level = "debug", skip(self, old_field), err)]
  pub async fn did_update_field_type_option(
    &self,
    view_id: &str,
    field_id: &str,
    old_field: Option<Arc<Field>>,
  ) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(view_id).await?;
    // If the id of the grouping field is equal to the updated field's id, then we need to
    // update the group setting
    if view_editor.group_id().await == field_id {
      view_editor.v_update_group_setting(field_id).await?;
    }
    view_editor
      .v_did_update_field_type_option(field_id, old_field)
      .await?;
    Ok(())
  }

  pub async fn get_view_editor(&self, view_id: &str) -> FlowyResult<Arc<DatabaseViewEditor>> {
    debug_assert!(!view_id.is_empty());
    if let Some(editor) = self.editor_map.read().await.get(view_id) {
      return Ok(editor.clone());
    }

    tracing::trace!("{:p} create view:{} editor", self, view_id);
    let mut editor_map = self.editor_map.write().await;
    let editor = Arc::new(
      DatabaseViewEditor::new(
        view_id.to_owned(),
        self.database_view_data.clone(),
        self.cell_cache.clone(),
      )
      .await,
    );
    editor_map.insert(view_id.to_owned(), editor.clone());
    Ok(editor)
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

pub fn gen_handler_id() -> String {
  nanoid!(10)
}
