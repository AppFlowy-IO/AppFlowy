use crate::FlowyError;

impl std::convert::From<serde_json::Error> for FlowyError {
    fn from(error: serde_json::Error) -> Self {
        FlowyError::internal().context(error)
    }
}
