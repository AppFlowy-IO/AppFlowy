use std::{fmt, fmt::Debug};
use strum_macros::Display;

macro_rules! static_doc_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> CollaborateError {
            CollaborateError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

pub type CollaborateResult<T> = std::result::Result<T, CollaborateError>;

#[derive(Debug, Clone)]
pub struct CollaborateError {
    pub code: ErrorCode,
    pub msg: String,
}

impl CollaborateError {
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
    static_doc_error!(record_not_found, ErrorCode::RecordNotFound);
    static_doc_error!(revision_conflict, ErrorCode::RevisionConflict);
}

impl fmt::Display for CollaborateError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}: {}", &self.code, &self.msg)
    }
}

#[derive(Debug, Clone, Display, PartialEq, Eq)]
pub enum ErrorCode {
    DocIdInvalid = 0,
    DocNotfound = 1,
    UndoFail = 200,
    RedoFail = 201,
    OutOfBound = 202,
    RevisionConflict = 203,
    RecordNotFound = 300,
    InternalError = 1000,
}

impl std::convert::From<lib_ot::errors::OTError> for CollaborateError {
    fn from(error: lib_ot::errors::OTError) -> Self {
        CollaborateError::new(ErrorCode::InternalError, "").context(error)
    }
}

impl std::convert::From<protobuf::ProtobufError> for CollaborateError {
    fn from(e: protobuf::ProtobufError) -> Self {
        CollaborateError::internal().context(e)
    }
}

pub(crate) fn internal_error<T>(e: T) -> CollaborateError
where
    T: std::fmt::Debug,
{
    CollaborateError::internal().context(e)
}
