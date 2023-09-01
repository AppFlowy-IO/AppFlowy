#[derive(Debug, thiserror::Error)]
pub enum FileStorageError {
  #[error("Http error: {0}")]
  HttpError(#[from] reqwest::Error),

  #[error("url error: {0}")]
  UrlError(#[from] url::ParseError),

  #[error("Excess storage size")]
  ExcessStorageSize,

  #[error("Internal failure: {0}")]
  Internal(#[from] anyhow::Error),
}
