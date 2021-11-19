use std::{fmt, fmt::Debug};
use strum_macros::Display;

macro_rules! static_doc_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> DocumentError {
            DocumentError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

pub type DocumentResult<T> = std::result::Result<T, DocumentError>;

#[derive(Debug, Clone)]
pub struct DocumentError {
    pub code: ErrorCode,
    pub msg: String,
}

impl DocumentError {
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

    static_doc_error!(internal, ErrorCode::InternalError);
    static_doc_error!(undo, ErrorCode::UndoFail);
    static_doc_error!(redo, ErrorCode::RedoFail);
    static_doc_error!(out_of_bound, ErrorCode::OutOfBound);
}

impl fmt::Display for DocumentError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}: {}", &self.code, &self.msg) }
}

#[derive(Debug, Clone, Display, PartialEq, Eq)]
pub enum ErrorCode {
    DocIdInvalid  = 0,
    DocNotfound   = 1,
    UndoFail      = 200,
    RedoFail      = 201,
    OutOfBound    = 202,
    InternalError = 1000,
}

impl std::convert::From<flowy_ot::errors::OTError> for DocumentError {
    fn from(error: flowy_ot::errors::OTError) -> Self {
        DocumentError::new(ErrorCode::InternalError, "").context(error)
    }
}

impl std::convert::From<protobuf::ProtobufError> for DocumentError {
    fn from(e: protobuf::ProtobufError) -> Self { DocumentError::internal().context(e) }
}
