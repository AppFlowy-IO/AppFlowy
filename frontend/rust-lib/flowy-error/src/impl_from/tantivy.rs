use tantivy::TantivyError;

use crate::{ErrorCode, FlowyError};

impl std::convert::From<TantivyError> for FlowyError {
  fn from(error: TantivyError) -> Self {
    FlowyError::new(ErrorCode::IndexWriterFailedCommit, error)
  }
}
