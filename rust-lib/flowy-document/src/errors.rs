use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use flowy_net::errors::ServerError;
use std::{convert::TryInto, fmt};

pub type DocResult<T> = std::result::Result<T, DocError>;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct DocError {
    #[pb(index = 1)]
    pub code: ErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

macro_rules! static_doc_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> DocError {
            DocError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

impl DocError {
    fn new(code: ErrorCode, msg: &str) -> Self {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    pub fn is_record_not_found(&self) -> bool { self.code == ErrorCode::DocNotfound }

    static_doc_error!(id_invalid, ErrorCode::DocIdInvalid);
    static_doc_error!(internal, ErrorCode::InternalError);
    static_doc_error!(not_found, ErrorCode::DocNotfound);
    static_doc_error!(unauthorized, ErrorCode::UserUnauthorized);
    static_doc_error!(ws, ErrorCode::WsConnectError);
    static_doc_error!(undo, ErrorCode::UndoFail);
    static_doc_error!(redo, ErrorCode::RedoFail);
    static_doc_error!(out_of_bound, ErrorCode::OutOfBound);
    static_doc_error!(duplicate_rev, ErrorCode::DuplicateRevision);
}

pub fn internal_error<T>(e: T) -> DocError
where
    T: std::fmt::Debug,
{
    DocError::internal().context(e)
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "DocIdInvalid")]
    DocIdInvalid      = 0,

    #[display(fmt = "DocNotfound")]
    DocNotfound       = 1,

    #[display(fmt = "Document websocket error")]
    WsConnectError    = 10,

    #[display(fmt = "Undo failed")]
    UndoFail          = 200,
    #[display(fmt = "Redo failed")]
    RedoFail          = 201,

    #[display(fmt = "Interval out of bound")]
    OutOfBound        = 202,

    #[display(fmt = "Duplicate revision")]
    DuplicateRevision = 400,

    #[display(fmt = "UserUnauthorized")]
    UserUnauthorized  = 999,

    #[display(fmt = "InternalError")]
    InternalError     = 1000,
}

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}

impl std::convert::From<flowy_database::Error> for DocError {
    fn from(error: flowy_database::Error) -> Self {
        match error {
            flowy_database::Error::NotFound => DocError::not_found().context(error),
            _ => DocError::internal().context(error),
        }
    }
}

impl std::convert::From<flowy_ot::errors::OTError> for DocError {
    fn from(error: flowy_ot::errors::OTError) -> Self { DocError::internal().context(error) }
}

impl std::convert::From<std::io::Error> for DocError {
    fn from(error: std::io::Error) -> Self { DocError::internal().context(error) }
}

impl std::convert::From<serde_json::Error> for DocError {
    fn from(error: serde_json::Error) -> Self { DocError::internal().context(error) }
}

impl std::convert::From<protobuf::ProtobufError> for DocError {
    fn from(e: protobuf::ProtobufError) -> Self { DocError::internal().context(e) }
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
        DocError::new(code, &error.msg)
    }
}

use flowy_net::errors::ErrorCode as ServerErrorCode;
use std::fmt::Debug;

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
