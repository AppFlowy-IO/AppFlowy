use reqwest::Error;

use crate::FlowyError;

impl std::convert::From<reqwest::Error> for FlowyError {
  fn from(error: Error) -> Self {
    FlowyError::http().with_context(error)
  }
}
