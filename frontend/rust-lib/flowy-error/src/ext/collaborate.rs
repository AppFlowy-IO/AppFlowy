use crate::FlowyError;

impl std::convert::From<flowy_collaboration::errors::CollaborateError> for FlowyError {
    fn from(error: flowy_collaboration::errors::CollaborateError) -> Self {
        FlowyError::internal().context(error)
    }
}
