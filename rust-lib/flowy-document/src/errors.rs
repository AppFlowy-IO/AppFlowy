use crate::services::file_manager::FileError;
use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::convert::TryInto;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct DocError {
    #[pb(index = 1)]
    pub code: DocErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

impl DocError {
    fn new(code: DocErrorCode, msg: &str) -> Self { Self { code, msg: msg.to_owned() } }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum DocErrorCode {
    #[display(fmt = "Unknown")]
    Unknown            = 0,

    #[display(fmt = "EditorDBInternalError")]
    EditorDBInternalError = 1,

    #[display(fmt = "EditorDBConnFailed")]
    EditorDBConnFailed = 2,

    #[display(fmt = "DocNameInvalid")]
    DocNameInvalid     = 10,

    #[display(fmt = "DocViewIdInvalid")]
    DocViewIdInvalid   = 11,

    #[display(fmt = "DocDescTooLong")]
    DocDescTooLong     = 12,

    #[display(fmt = "DocOpenFileError")]
    DocOpenFileError   = 13,

    #[display(fmt = "DocFilePathInvalid")]
    DocFilePathInvalid = 14,

    #[display(fmt = "EditorUserNotLoginYet")]
    EditorUserNotLoginYet = 100,
}

impl std::default::Default for DocErrorCode {
    fn default() -> Self { DocErrorCode::Unknown }
}

impl std::convert::From<flowy_database::Error> for DocError {
    fn from(error: flowy_database::Error) -> Self { ErrorBuilder::new(DocErrorCode::EditorDBInternalError).error(error).build() }
}

impl std::convert::From<FileError> for DocError {
    fn from(error: FileError) -> Self { ErrorBuilder::new(DocErrorCode::DocOpenFileError).error(error).build() }
}

impl flowy_dispatch::Error for DocError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

pub type ErrorBuilder = flowy_infra::errors::Builder<DocErrorCode, DocError>;

impl flowy_infra::errors::Build<DocErrorCode> for DocError {
    fn build(code: DocErrorCode, msg: String) -> Self { DocError::new(code, &msg) }
}
