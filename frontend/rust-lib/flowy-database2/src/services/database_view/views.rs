use std::collections::HashMap;
use std::sync::Arc;

use collab_database::fields::Field;
use collab_database::rows::{Row, RowId};
use nanoid::nanoid;
use tokio::sync::{broadcast, RwLock};

use flowy_error::FlowyResult;
use lib_infra::future::Fut;

use crate::services::cell::CellCache;
use crate::services::database::{DatabaseRowEvent, MutexDatabase};
use crate::services::database_view::{DatabaseViewData, DatabaseViewEditor};
use crate::services::group::RowChangeset;

pub type RowEventSender = broadcast::Sender<DatabaseRowEvent>;
pub type RowEventReceiver = broadcast::Receiver<DatabaseRowEvent>;

pub struct DatabaseViews {
  #[allow(dead_code)]
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
  ) -> FlowyResult<Self> {
    let editor_map = Arc::new(RwLock::new(HashMap::default()));
    Ok(Self {
      database,
      database_view_data,
      cell_cache,
      editor_map,
    })
  }

  pub async fn close_view(&self, view_id: &str) -> bool {
    let mut editor_map = self.editor_map.write().await;
    if let Some(view) = editor_map.remove(view_id) {
      view.close().await;
    }
    editor_map.is_empty()
  }

  pub async fn editors(&self) -> Vec<Arc<DatabaseViewEditor>> {
    self.editor_map.read().await.values().cloned().collect()
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
      .v_move_group_row(&row, &mut row_changeset, &to_group_id, to_row_id)
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
    old_field: &Field,
  ) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(view_id).await?;
    // If the id of the grouping field is equal to the updated field's id, then we need to
    // update the group setting
    if view_editor.is_grouping_field(field_id).await {
      view_editor.v_update_grouping_field(field_id).await?;
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

    let mut editor_map = self.editor_map.write().await;
    let editor = Arc::new(
      DatabaseViewEditor::new(
        view_id.to_owned(),
        self.database_view_data.clone(),
        self.cell_cache.clone(),
      )
      .await?,
    );
    editor_map.insert(view_id.to_owned(), editor.clone());
    Ok(editor)
  }
}

pub fn gen_handler_id() -> String {
  nanoid!(10)
}
