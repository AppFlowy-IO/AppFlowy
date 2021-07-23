use crate::services::file_manager::FileError;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::convert::TryInto;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct EditorError {
    #[pb(index = 1)]
    pub code: EditorErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

impl EditorError {
    fn new(code: EditorErrorCode, msg: &str) -> Self {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum EditorErrorCode {
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

    #[display(fmt = "DocDescTooLong")]
    DocFileError       = 13,

    #[display(fmt = "EditorUserNotLoginYet")]
    EditorUserNotLoginYet = 100,
}

impl std::default::Default for EditorErrorCode {
    fn default() -> Self { EditorErrorCode::Unknown }
}

impl std::convert::From<flowy_database::result::Error> for EditorError {
    fn from(error: flowy_database::result::Error) -> Self {
        ErrorBuilder::new(EditorErrorCode::EditorDBInternalError)
            .error(error)
            .build()
    }
}

impl std::convert::From<FileError> for EditorError {
    fn from(error: FileError) -> Self {
        ErrorBuilder::new(EditorErrorCode::DocFileError)
            .error(error)
            .build()
    }
}

impl flowy_dispatch::Error for EditorError {
    fn as_response(&self) -> EventResponse {
        let bytes: Vec<u8> = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

pub struct ErrorBuilder {
    pub code: EditorErrorCode,
    pub msg: Option<String>,
}

impl ErrorBuilder {
    pub fn new(code: EditorErrorCode) -> Self { ErrorBuilder { code, msg: None } }

    pub fn msg<T>(mut self, msg: T) -> Self
    where
        T: Into<String>,
    {
        self.msg = Some(msg.into());
        self
    }

    pub fn error<T>(mut self, msg: T) -> Self
    where
        T: std::fmt::Debug,
    {
        self.msg = Some(format!("{:?}", msg));
        self
    }

    pub fn build(mut self) -> EditorError {
        EditorError::new(self.code, &self.msg.take().unwrap_or("".to_owned()))
    }
}
