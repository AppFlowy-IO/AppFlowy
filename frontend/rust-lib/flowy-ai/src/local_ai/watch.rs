use crate::local_ai::resource::WatchDiskEvent;
use af_plugin::core::path::{install_path, ollama_plugin_path};
use flowy_error::{FlowyError, FlowyResult};
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver};
use tracing::{error, trace};

pub struct WatchContext {
  #[allow(dead_code)]
  watcher: notify::RecommendedWatcher,
}

pub fn watch_offline_app() -> FlowyResult<(WatchContext, UnboundedReceiver<WatchDiskEvent>)> {
  use notify::{Event, Watcher};

  let install_path = install_path().ok_or_else(|| {
    FlowyError::internal().with_context("Unsupported platform for offline app watching")
  })?;
  let (tx, rx) = unbounded_channel();
  let app_path = ollama_plugin_path();
  let mut watcher = notify::recommended_watcher(move |res: Result<Event, _>| match res {
    Ok(event) => {
      if event.paths.iter().any(|path| path == &app_path) {
        trace!("watch event: {:?}", event);
        match event.kind {
          notify::EventKind::Create(_) => {
            if let Err(err) = tx.send(WatchDiskEvent::Create) {
              error!("watch send error: {:?}", err)
            }
          },
          notify::EventKind::Remove(_) => {
            if let Err(err) = tx.send(WatchDiskEvent::Remove) {
              error!("watch send error: {:?}", err)
            }
          },
          _ => {
            trace!("unhandle watch event: {:?}", event);
          },
        }
      }
    },
    Err(e) => error!("watch error: {:?}", e),
  })
  .map_err(|err| FlowyError::internal().with_context(err))?;
  watcher
    .watch(&install_path, notify::RecursiveMode::NonRecursive)
    .map_err(|err| FlowyError::internal().with_context(err))?;

  Ok((WatchContext { watcher }, rx))
}
