use crate::FlowyError;
use flowy_client_ws::WSErrorCode;

impl std::convert::From<WSErrorCode> for FlowyError {
  fn from(code: WSErrorCode) -> Self {
    match code {
      WSErrorCode::Internal => FlowyError::internal().context(code),
    }
  }
}
