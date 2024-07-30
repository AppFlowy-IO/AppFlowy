use crate::local_ai::local_llm_resource::WatchDiskEvent;
use flowy_error::{FlowyError, FlowyResult};
use notify::{Event, RecursiveMode, Watcher};
use std::path::PathBuf;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver};
use tracing::error;

pub struct WatchContext {
  #[allow(dead_code)]
  watcher: notify::RecommendedWatcher,
  pub path: PathBuf,
}

pub fn watch_path(path: PathBuf) -> FlowyResult<(WatchContext, UnboundedReceiver<WatchDiskEvent>)> {
  let (tx, rx) = unbounded_channel();
  let mut watcher = notify::recommended_watcher(move |res: Result<Event, _>| match res {
    Ok(event) => match event.kind {
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
      _ => {},
    },
    Err(e) => error!("watch error: {:?}", e),
  })
  .map_err(|err| FlowyError::internal().with_context(err))?;
  watcher
    .watch(&path, RecursiveMode::Recursive)
    .map_err(|err| FlowyError::internal().with_context(err))?;

  Ok((WatchContext { watcher, path }, rx))
}
