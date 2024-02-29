use tantivy::{directory::error::OpenDirectoryError, query::QueryParserError, TantivyError};

use crate::{ErrorCode, FlowyError};

impl std::convert::From<TantivyError> for FlowyError {
  fn from(error: TantivyError) -> Self {
    FlowyError::new(ErrorCode::IndexWriterFailedCommit, error)
  }
}

impl std::convert::From<OpenDirectoryError> for FlowyError {
  fn from(error: OpenDirectoryError) -> Self {
    FlowyError::new(ErrorCode::FailedToOpenIndexDir, error)
  }
}

impl std::convert::From<QueryParserError> for FlowyError {
  fn from(error: QueryParserError) -> Self {
    FlowyError::new(ErrorCode::FailedToParseQuery, error)
  }
}
