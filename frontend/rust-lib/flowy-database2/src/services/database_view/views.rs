use crate::entities::FieldType;
use crate::manager::DatabaseUser2;
use crate::services::cell::CellCache;
use crate::services::database::{Database, DatabaseRowEvent};
use crate::services::database_view::{
  DatabaseViewChangedNotifier, DatabaseViewData, DatabaseViewEditor,
};
use crate::services::field::TypeOptionCellDataHandler;
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
  cell_cache: CellCache,
  database_view_data: Arc<dyn DatabaseViewData>,
  editor_map: Arc<RwLock<HashMap<String, Arc<DatabaseViewEditor>>>>,
}

impl DatabaseViews {
  pub async fn new(
    cell_cache: CellCache,
    database_view_data: Arc<dyn DatabaseViewData>,
    row_event_rx: RowEventReceiver,
  ) -> FlowyResult<Self> {
    let editor_map = Arc::new(RwLock::new(HashMap::default()));
    listen_on_database_row_event(row_event_rx, editor_map.clone());
    Ok(Self {
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
