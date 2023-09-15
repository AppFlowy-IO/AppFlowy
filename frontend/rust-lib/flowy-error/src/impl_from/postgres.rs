use crate::FlowyError;

impl std::convert::From<tokio_postgres::Error> for FlowyError {
  fn from(error: tokio_postgres::Error) -> Self {
    FlowyError::internal().with_context(error)
  }
}
