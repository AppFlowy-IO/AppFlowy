use crate::local_ai::resource::WatchDiskEvent;
use flowy_error::{FlowyError, FlowyResult};
use std::path::PathBuf;
use std::process::Command;
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver};
use tracing::{error, trace};

#[cfg(windows)]
use winreg::{enums::*, RegKey};

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

pub fn is_plugin_ready() -> bool {
  ollama_plugin_path().exists() || ollama_plugin_command_available()
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

pub(crate) fn ollama_plugin_command_available() -> bool {
  if cfg!(windows) {
    #[cfg(windows)]
    {
      // 1. Try "where" command first
      let output = Command::new("cmd")
        .args(["/C", "where", "ollama_ai_plugin"])
        .output();
      if let Ok(output) = output {
        if !output.stdout.is_empty() {
          return true;
        }
      }

      // 2. Fallback: Check registry PATH for the executable
      let path_dirs = get_windows_path_dirs();
      let plugin_exe = "ollama_ai_plugin.exe"; // Adjust name if needed

      path_dirs.iter().any(|dir| {
        let full_path = std::path::Path::new(dir).join(plugin_exe);
        full_path.exists()
      })
    }

    #[cfg(not(windows))]
    false
  } else {
    let output = Command::new("command")
      .args(&["-v", "ollama_ai_plugin"])
      .output();
    match output {
      Ok(o) => !o.stdout.is_empty(),
      _ => false,
    }
  }
}

#[cfg(windows)]
fn get_windows_path_dirs() -> Vec<String> {
  let mut paths = Vec::new();

  // Check HKEY_CURRENT_USER\Environment
  let hkcu = RegKey::predef(HKEY_CURRENT_USER);
  if let Ok(env) = hkcu.open_subkey("Environment") {
    if let Ok(path) = env.get_value::<String, _>("Path") {
      paths.extend(path.split(';').map(|s| s.trim().to_string()));
    }
  }

  // Check HKEY_LOCAL_MACHINE\SYSTEM\...\Environment
  let hklm = RegKey::predef(HKEY_LOCAL_MACHINE);
  if let Ok(env) = hklm.open_subkey(r"SYSTEM\CurrentControlSet\Control\Session Manager\Environment")
  {
    if let Ok(path) = env.get_value::<String, _>("Path") {
      paths.extend(path.split(';').map(|s| s.trim().to_string()));
    }
  }
  paths
}

#[cfg(test)]
mod tests {
  use crate::local_ai::watch::ollama_plugin_command_available;

  #[test]
  fn test_command_import() {
    let result = ollama_plugin_command_available();
    println!("ollama plugin exist: {:?}", result);
  }
}
