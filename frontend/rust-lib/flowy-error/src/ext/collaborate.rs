use crate::FlowyError;

use flowy_sync::errors::ErrorCode;

impl std::convert::From<flowy_sync::errors::CollaborateError> for FlowyError {
    fn from(error: flowy_sync::errors::CollaborateError) -> Self {
        match error.code {
            ErrorCode::RecordNotFound => FlowyError::record_not_found().context(error.msg),
            _ => FlowyError::internal().context(error.msg),
        }
    }
}
