use flowy_database::DataBaseError;
use std::sync::PoisonError;

#[derive(Debug)]
pub enum UserError {
    DBInit(String),
    DBNotInit,
    UserNotLogin,
    DBConnection(String),
    PoisonError(String),
}

impl std::convert::From<DataBaseError> for UserError {
    fn from(error: DataBaseError) -> Self { UserError::DBInit(format!("{:?}", error)) }
}

impl<T> std::convert::From<PoisonError<T>> for UserError {
    fn from(error: PoisonError<T>) -> Self { UserError::PoisonError(format!("{:?}", error)) }
}

impl std::convert::From<flowy_sqlite::Error> for UserError {
    fn from(e: flowy_sqlite::Error) -> Self { UserError::DBConnection(format!("{:?}", e)) }
}
