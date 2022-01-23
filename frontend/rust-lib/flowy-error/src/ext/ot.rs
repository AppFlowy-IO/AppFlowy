use crate::FlowyError;

impl std::convert::From<lib_ot::errors::OTError> for FlowyError {
    fn from(error: lib_ot::errors::OTError) -> Self {
        FlowyError::internal().context(error)
    }
}
