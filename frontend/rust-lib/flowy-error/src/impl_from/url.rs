use crate::{ErrorCode, FlowyError};

impl std::convert::From<url::ParseError> for FlowyError {
  fn from(error: url::ParseError) -> Self {
    FlowyError::new(ErrorCode::InvalidURL, "").with_context(error)
  }
}
