use collab_database::error::DatabaseError;
use collab_document::error::DocumentError;
use collab_persistence::PersistenceError;

use crate::{ErrorCode, FlowyError};

impl From<PersistenceError> for FlowyError {
  fn from(err: PersistenceError) -> Self {
    match err {
      PersistenceError::RocksdbCorruption(_) => FlowyError::new(ErrorCode::RocksdbCorruption, err),
      PersistenceError::RocksdbIOError(_) => FlowyError::new(ErrorCode::RocksdbIOError, err),
      _ => FlowyError::new(ErrorCode::RocksdbInternal, err),
    }
  }
}
impl From<DatabaseError> for FlowyError {
  fn from(error: DatabaseError) -> Self {
    FlowyError::internal().with_context(error)
  }
}

impl From<DocumentError> for FlowyError {
  fn from(error: DocumentError) -> Self {
    FlowyError::internal().with_context(error)
  }
}
