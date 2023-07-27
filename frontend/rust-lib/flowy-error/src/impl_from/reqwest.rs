use crate::FlowyError;
use reqwest::Error;

impl std::convert::From<reqwest::Error> for FlowyError {
  fn from(error: Error) -> Self {
    FlowyError::http().context(error)
  }
}
