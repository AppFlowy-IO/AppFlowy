use std::sync::PoisonError;

#[derive(Debug)]
pub enum UserError {
    DBInitFail(String),
    PoisonError(String),
}

impl std::convert::From<flowy_db::FlowyDBError> for UserError {
    fn from(error: flowy_db::FlowyDBError) -> Self { UserError::DBInitFail(format!("{:?}", error)) }
}

impl<T> std::convert::From<PoisonError<T>> for UserError {
    fn from(error: PoisonError<T>) -> Self { UserError::PoisonError(format!("{:?}", error)) }
}
