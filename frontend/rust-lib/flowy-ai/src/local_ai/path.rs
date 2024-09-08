use std::path::PathBuf;

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
