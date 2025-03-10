use crate::local_ai::resource::WatchDiskEvent;
use flowy_error::{FlowyError, FlowyResult};
use std::path::PathBuf;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver};
use tracing::{error, trace};

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
#[allow(dead_code)]
pub struct WatchContext {
  watcher: notify::RecommendedWatcher,
  pub path: PathBuf,
}

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
#[allow(dead_code)]
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

  Ok((
    WatchContext {
      watcher,
      path: install_path,
    },
    rx,
  ))
}

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
pub(crate) fn install_path() -> Option<PathBuf> {
  None
}

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub(crate) fn install_path() -> Option<PathBuf> {
  #[cfg(target_os = "windows")]
  return None;

  #[cfg(target_os = "macos")]
  return Some(PathBuf::from("/usr/local/bin"));

  #[cfg(target_os = "linux")]
  return None;
}

#[cfg(not(any(target_os = "windows", target_os = "macos", target_os = "linux")))]
pub(crate) fn offline_app_path() -> PathBuf {
  PathBuf::new()
}

#[cfg(any(target_os = "windows", target_os = "macos", target_os = "linux"))]
pub(crate) fn ollama_plugin_path() -> std::path::PathBuf {
  #[cfg(target_os = "windows")]
  {
    // Use LOCALAPPDATA for a user-specific installation path on Windows.
    let local_appdata =
      std::env::var("LOCALAPPDATA").unwrap_or_else(|_| "C:\\Program Files".to_string());
    std::path::PathBuf::from(local_appdata).join("Programs\\appflowy_plugin\\ollama_ai_plugin.exe")
  }

  #[cfg(target_os = "macos")]
  {
    let offline_app = "ollama_ai_plugin";
    std::path::PathBuf::from(format!("/usr/local/bin/{}", offline_app))
  }

  #[cfg(target_os = "linux")]
  {
    let offline_app = "ollama_ai_plugin";
    std::path::PathBuf::from(format!("/usr/local/bin/{}", offline_app))
  }
}
