use crate::FlowyError;

impl std::convert::From<flowy_database::Error> for FlowyError {
    fn from(error: flowy_database::Error) -> Self {
        FlowyError::internal().context(error)
    }
}

impl std::convert::From<::r2d2::Error> for FlowyError {
    fn from(error: r2d2::Error) -> Self {
        FlowyError::internal().context(error)
    }
}
