use flowy_error::FlowyError;
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

impl From<PersistenceError> for FlowyError {
  fn from(value: PersistenceError) -> Self {
    match value {
      PersistenceError::Internal(value) => FlowyError::internal().with_context(value),
      PersistenceError::SerdeError(value) => FlowyError::serde().with_context(value),
      PersistenceError::RecordNotFound(value) => FlowyError::record_not_found().with_context(value),
    }
  }
}
