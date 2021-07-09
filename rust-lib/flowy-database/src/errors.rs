use flowy_sqlite::Error;
use std::io;

#[derive(Debug)]
pub enum DataBaseError {
    InitError(String),
    IOError(String),
}

impl std::convert::From<flowy_sqlite::Error> for DataBaseError {
    fn from(error: flowy_sqlite::Error) -> Self { DataBaseError::InitError(format!("{:?}", error)) }
}

impl std::convert::From<io::Error> for DataBaseError {
    fn from(error: io::Error) -> Self { DataBaseError::IOError(format!("{:?}", error)) }
}
