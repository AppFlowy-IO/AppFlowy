use crate::local_ai::local_llm_resource::WatchDiskEvent;
use flowy_error::{FlowyError, FlowyResult};
use notify::{Event, RecursiveMode, Watcher};
use std::path::PathBuf;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver};
use tracing::{error, trace};

pub struct WatchContext {
  #[allow(dead_code)]
  watcher: notify::RecommendedWatcher,
  pub path: PathBuf,
}

pub fn watch_offline_app() -> FlowyResult<(WatchContext, UnboundedReceiver<WatchDiskEvent>)> {
  let install_path = install_path().ok_or_else(|| {
    FlowyError::internal().with_context("Unsupported platform for offline app watching")
  })?;
  let (tx, rx) = unbounded_channel();
  let app_path = offline_app_path();
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
    .watch(&install_path, RecursiveMode::NonRecursive)
    .map_err(|err| FlowyError::internal().with_context(err))?;

  Ok((
    WatchContext {
      watcher,
      path: install_path,
    },
    rx,
  ))
}

pub(crate) fn install_path() -> Option<PathBuf> {
  #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
  return None;

  #[cfg(target_os = "windows")]
  return None;

  #[cfg(target_os = "macos")]
  return Some(PathBuf::from("/usr/local/bin"));

  #[cfg(target_os = "linux")]
  return None;
}

pub(crate) fn offline_app_path() -> PathBuf {
  #[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
  return PathBuf::new();

  #[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
  {
    let offline_app = "appflowy_ai_plugin";
    #[cfg(target_os = "windows")]
    return PathBuf::from(format!("/usr/local/bin/{}", offline_app));

    #[cfg(target_os = "macos")]
    return PathBuf::from(format!("/usr/local/bin/{}", offline_app));

    #[cfg(target_os = "linux")]
    return PathBuf::from(format!("/usr/local/bin/{}", offline_app));
  }
}
