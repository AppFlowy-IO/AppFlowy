use collab_database::database::Database;
use std::collections::HashMap;
use std::sync::Arc;

use crate::services::cell::CellCache;
use crate::services::database::DatabaseRowEvent;
use crate::services::database_view::{DatabaseViewEditor, DatabaseViewOperation};
use collab::lock::RwLock;
use flowy_error::FlowyResult;
use nanoid::nanoid;
use tokio::sync::broadcast;

pub type RowEventSender = broadcast::Sender<DatabaseRowEvent>;
pub type RowEventReceiver = broadcast::Receiver<DatabaseRowEvent>;
pub type EditorByViewId = HashMap<String, Arc<DatabaseViewEditor>>;

pub struct DatabaseViews {
  #[allow(dead_code)]
  database: Arc<RwLock<Database>>,
  cell_cache: CellCache,
  view_operation: Arc<dyn DatabaseViewOperation>,
  view_editors: Arc<RwLock<EditorByViewId>>,
}

impl DatabaseViews {
  pub async fn new(
    database: Arc<RwLock<Database>>,
    cell_cache: CellCache,
    view_operation: Arc<dyn DatabaseViewOperation>,
    view_editors: Arc<RwLock<EditorByViewId>>,
  ) -> FlowyResult<Self> {
    Ok(Self {
      database,
      view_operation,
      cell_cache,
      view_editors,
    })
  }

  pub async fn close_view(&self, view_id: &str) {
    let mut lock_guard = self.view_editors.write().await;
    if let Some(view) = lock_guard.remove(view_id) {
      view.close().await;
    }
  }

  pub async fn num_editors(&self) -> usize {
    self.view_editors.read().await.len()
  }

  pub async fn editors(&self) -> Vec<Arc<DatabaseViewEditor>> {
    self.view_editors.read().await.values().cloned().collect()
  }

  pub async fn get_or_init_view_editor(
    &self,
    view_id: &str,
  ) -> FlowyResult<Arc<DatabaseViewEditor>> {
    debug_assert!(!view_id.is_empty());
    if let Some(editor) = self.view_editors.read().await.get(view_id) {
      return Ok(editor.clone());
    }

    let mut editor_map = self.view_editors.write().await;
    let database_id = self.database.read().await.get_database_id();
    let editor = Arc::new(
      DatabaseViewEditor::new(
        database_id,
        view_id.to_owned(),
        self.view_operation.clone(),
        self.cell_cache.clone(),
      )
      .await?,
    );
    editor_map.insert(view_id.to_owned(), editor.clone());
    Ok(editor)
  }

  pub async fn get_view_editor(&self, view_id: &str) -> Option<Arc<DatabaseViewEditor>> {
    self.view_editors.read().await.get(view_id).cloned()
  }
}

pub fn gen_handler_id() -> String {
  nanoid!(10)
}
