use crate::FlowyError;

use flowy_collaboration::errors::ErrorCode;

impl std::convert::From<flowy_collaboration::errors::CollaborateError> for FlowyError {
    fn from(error: flowy_collaboration::errors::CollaborateError) -> Self {
        match error.code {
            ErrorCode::RecordNotFound => FlowyError::record_not_found().context(error.msg),
            _ => FlowyError::internal().context(error.msg),
        }
    }
}
