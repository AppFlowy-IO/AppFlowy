use web_sys::DomException;

#[derive(Debug, thiserror::Error)]
pub enum PersistenceError {
  #[error(transparent)]
  Internal(#[from] anyhow::Error),

  #[error(transparent)]
  SerdeError(#[from] serde_json::Error),

  #[error("{0}")]
  RecordNotFound(String),
}

impl From<DomException> for PersistenceError {
  fn from(value: DomException) -> Self {
    PersistenceError::Internal(anyhow::anyhow!("DOMException: {:?}", value))
  }
}
