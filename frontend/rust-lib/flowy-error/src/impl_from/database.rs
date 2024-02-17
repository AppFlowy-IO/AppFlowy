use crate::FlowyError;

impl std::convert::From<flowy_sqlite::Error> for FlowyError {
  fn from(error: flowy_sqlite::Error) -> Self {
    FlowyError::internal().with_context(error)
  }
}

impl std::convert::From<::r2d2::Error> for FlowyError {
  fn from(error: r2d2::Error) -> Self {
    FlowyError::internal().with_context(error)
  }
}
