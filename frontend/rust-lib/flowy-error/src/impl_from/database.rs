use crate::FlowyError;
use flowy_sqlite::Error;

impl std::convert::From<flowy_sqlite::Error> for FlowyError {
  fn from(error: flowy_sqlite::Error) -> Self {
    match error {
      Error::NotFound => FlowyError::record_not_found(),
      _ => FlowyError::internal().with_context(error),
    }
  }
}

impl std::convert::From<::r2d2::Error> for FlowyError {
  fn from(error: r2d2::Error) -> Self {
    FlowyError::internal().with_context(error)
  }
}
