use crate::FlowyError;

use flowy_client_sync::errors::ErrorCode;

impl std::convert::From<flowy_client_sync::errors::SyncError> for FlowyError {
  fn from(error: flowy_client_sync::errors::SyncError) -> Self {
    match error.code {
      ErrorCode::RecordNotFound => FlowyError::record_not_found().context(error.msg),
      _ => FlowyError::internal().context(error.msg),
    }
  }
}
