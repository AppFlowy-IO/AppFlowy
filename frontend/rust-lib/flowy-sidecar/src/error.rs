/// The error type of `tauri-utils`.
#[derive(Debug, thiserror::Error)]
#[non_exhaustive]
pub enum Error {
  /// Target triple architecture error
  #[error("Unable to determine target-architecture")]
  Architecture,
  /// Target triple OS error
  #[error("Unable to determine target-os")]
  Os,
  /// Target triple environment error
  #[error("Unable to determine target-environment")]
  Environment,
  /// Tried to get resource on an unsupported platform
  #[error("Unsupported platform for reading resources")]
  UnsupportedPlatform,
  /// Get parent process error
  #[error("Could not get parent process")]
  ParentProcess,
  /// Get parent process PID error
  #[error("Could not get parent PID")]
  ParentPid,
  /// Get child process error
  #[error("Could not get child process")]
  ChildProcess,
  /// IO error
  #[error("{0}")]
  Io(#[from] std::io::Error),
  /// Invalid pattern.
  #[error("invalid pattern `{0}`. Expected either `brownfield` or `isolation`.")]
  InvalidPattern(String),
}
