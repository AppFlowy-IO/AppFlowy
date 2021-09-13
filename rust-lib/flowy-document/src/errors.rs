use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use flowy_net::errors::ServerError;
use std::{convert::TryInto, fmt};

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct DocError {
    #[pb(index = 1)]
    pub code: ErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

impl DocError {
    fn new(code: ErrorCode, msg: &str) -> Self { Self { code, msg: msg.to_owned() } }

    pub fn is_record_not_found(&self) -> bool { self.code == ErrorCode::DocNotfound }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "DocIdInvalid")]
    DocIdInvalid     = 0,

    #[display(fmt = "DocNotfound")]
    DocNotfound      = 1,

    #[display(fmt = "UserUnauthorized")]
    UserUnauthorized = 999,

    #[display(fmt = "InternalError")]
    InternalError    = 1000,
}

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}

impl std::convert::From<flowy_database::Error> for DocError {
    fn from(error: flowy_database::Error) -> Self {
        match error {
            flowy_database::Error::NotFound => ErrorBuilder::new(ErrorCode::DocNotfound).error(error).build(),
            _ => ErrorBuilder::new(ErrorCode::InternalError).error(error).build(),
        }
    }
}

// impl std::convert::From<::r2d2::Error> for DocError {
//     fn from(error: r2d2::Error) -> Self {
// ErrorBuilder::new(ErrorCode::InternalError).error(error).build() } }

// impl std::convert::From<flowy_sqlite::Error> for DocError {
//     fn from(error: flowy_sqlite::Error) -> Self {
// ErrorBuilder::new(ErrorCode::InternalError).error(error).build() } }

impl std::convert::From<flowy_net::errors::ServerError> for DocError {
    fn from(error: ServerError) -> Self {
        let code = server_error_to_doc_error(error.code);
        ErrorBuilder::new(code).error(error.msg).build()
    }
}

use flowy_net::errors::ErrorCode as ServerErrorCode;

fn server_error_to_doc_error(code: ServerErrorCode) -> ErrorCode {
    match code {
        ServerErrorCode::UserUnauthorized => ErrorCode::UserUnauthorized,
        ServerErrorCode::RecordNotFound => ErrorCode::DocNotfound,
        _ => ErrorCode::InternalError,
    }
}

impl flowy_dispatch::Error for DocError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

impl fmt::Display for DocError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}: {}", &self.code, &self.msg) }
}

pub type ErrorBuilder = flowy_infra::errors::Builder<ErrorCode, DocError>;
impl flowy_infra::errors::Build<ErrorCode> for DocError {
    fn build(code: ErrorCode, msg: String) -> Self { DocError::new(code, &msg) }
}
