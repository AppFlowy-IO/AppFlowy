use flowy_infra::Error;
use std::io;

#[derive(Debug)]
pub enum FlowyDBError {
    InitError(String),
    IOError(String),
}

impl std::convert::From<flowy_infra::Error> for FlowyDBError {
    fn from(error: flowy_infra::Error) -> Self { FlowyDBError::InitError(format!("{:?}", error)) }
}

impl std::convert::From<io::Error> for FlowyDBError {
    fn from(error: io::Error) -> Self { FlowyDBError::IOError(format!("{:?}", error)) }
}
