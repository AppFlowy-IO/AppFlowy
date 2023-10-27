use std::collections::HashMap;
use std::sync::Arc;

use collab_database::database::MutexDatabase;
use collab_database::rows::{RowDetail, RowId};
use nanoid::nanoid;
use tokio::sync::{broadcast, RwLock};

use flowy_error::{FlowyError, FlowyResult};
use lib_infra::future::Fut;

use crate::services::cell::CellCache;
use crate::services::database::DatabaseRowEvent;
use crate::services::database_view::{DatabaseViewEditor, DatabaseViewOperation};
use crate::services::group::RowChangeset;

pub type RowEventSender = broadcast::Sender<DatabaseRowEvent>;
pub type RowEventReceiver = broadcast::Receiver<DatabaseRowEvent>;
pub type EditorByViewId = HashMap<String, Arc<DatabaseViewEditor>>;
pub struct DatabaseViews {
  #[allow(dead_code)]
  database: Arc<MutexDatabase>,
  cell_cache: CellCache,
  view_operation: Arc<dyn DatabaseViewOperation>,
  editor_by_view_id: Arc<RwLock<EditorByViewId>>,
}

impl DatabaseViews {
  pub async fn new(
    database: Arc<MutexDatabase>,
    cell_cache: CellCache,
    view_operation: Arc<dyn DatabaseViewOperation>,
    editor_by_view_id: Arc<RwLock<EditorByViewId>>,
  ) -> FlowyResult<Self> {
    Ok(Self {
      database,
      view_operation,
      cell_cache,
      editor_by_view_id,
    })
  }

  pub async fn close_view(&self, view_id: &str) -> bool {
    let mut editor_map = self.editor_by_view_id.write().await;
    if let Some(view) = editor_map.remove(view_id) {
      view.close().await;
    }
    editor_map.is_empty()
  }

  pub async fn editors(&self) -> Vec<Arc<DatabaseViewEditor>> {
    self
      .editor_by_view_id
      .read()
      .await
      .values()
      .cloned()
      .collect()
  }

  /// It may generate a RowChangeset when the Row was moved from one group to another.
  /// The return value, [RowChangeset], contains the changes made by the groups.
  ///
  pub async fn move_group_row(
    &self,
    view_id: &str,
    row_detail: Arc<RowDetail>,
    to_group_id: String,
    to_row_id: Option<RowId>,
    recv_row_changeset: impl FnOnce(RowChangeset) -> Fut<()>,
  ) -> FlowyResult<()> {
    let view_editor = self.get_view_editor(view_id).await?;
    let mut row_changeset = RowChangeset::new(row_detail.row.id.clone());
    view_editor
      .v_move_group_row(&row_detail, &mut row_changeset, &to_group_id, to_row_id)
      .await;

    if !row_changeset.is_empty() {
      recv_row_changeset(row_changeset).await;
    }

    Ok(())
  }

  pub async fn get_view_editor(&self, view_id: &str) -> FlowyResult<Arc<DatabaseViewEditor>> {
    debug_assert!(!view_id.is_empty());
    if let Some(editor) = self.editor_by_view_id.read().await.get(view_id) {
      return Ok(editor.clone());
    }

    let mut editor_map = self.editor_by_view_id.try_write().map_err(|err| {
      FlowyError::internal().with_context(format!(
        "fail to acquire the lock of editor_by_view_id: {}",
        err
      ))
    })?;
    let editor = Arc::new(
      DatabaseViewEditor::new(
        view_id.to_owned(),
        self.view_operation.clone(),
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
