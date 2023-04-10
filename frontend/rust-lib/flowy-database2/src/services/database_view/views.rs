use crate::manager::DatabaseUser2;
use crate::services::cell::CellCache;
use crate::services::database::DatabaseRowEvent;
use crate::services::database_view::DatabaseViewEditor;
use flowy_error::FlowyResult;
use std::borrow::Cow;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{broadcast, RwLock};

pub struct DatabaseViews {
  user: Arc<dyn DatabaseUser2>,
  cell_cache: CellCache,
  editor_map: Arc<RwLock<HashMap<String, Arc<DatabaseViewEditor>>>>,
}

impl DatabaseViews {
  pub async fn new(
    user: Arc<dyn DatabaseUser2>,
    cell_cache: CellCache,
    row_event_tx: broadcast::Receiver<DatabaseRowEvent>,
  ) -> FlowyResult<Self> {
    let editor_map = Arc::new(RwLock::new(HashMap::default()));
    listen_on_database_row_event(row_event_tx, editor_map.clone());
    Ok(Self {
      user,
      cell_cache,
      editor_map,
    })
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
