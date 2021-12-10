use crate::protobuf::ErrorCode as ProtoBufErrorCode;

use derive_more::Display;
use flowy_derive::ProtoBuf_Enum;
use protobuf::ProtobufEnum;
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "Workspace name can not be empty or whitespace")]
    WorkspaceNameInvalid = 0,

    #[display(fmt = "Workspace id can not be empty or whitespace")]
    WorkspaceIdInvalid   = 1,

    #[display(fmt = "Color style of the App is invalid")]
    AppColorStyleInvalid = 2,

    #[display(fmt = "Workspace desc is invalid")]
    WorkspaceDescTooLong = 3,

    #[display(fmt = "Workspace description too long")]
    WorkspaceNameTooLong = 4,

    #[display(fmt = "App id can not be empty or whitespace")]
    AppIdInvalid         = 10,

    #[display(fmt = "App name can not be empty or whitespace")]
    AppNameInvalid       = 11,

    #[display(fmt = "View name can not be empty or whitespace")]
    ViewNameInvalid      = 20,

    #[display(fmt = "Thumbnail of the view is invalid")]
    ViewThumbnailInvalid = 21,

    #[display(fmt = "View id can not be empty or whitespace")]
    ViewIdInvalid        = 22,

    #[display(fmt = "View desc too long")]
    ViewDescTooLong      = 23,

    #[display(fmt = "View data is invalid")]
    ViewDataInvalid      = 24,

    #[display(fmt = "View name too long")]
    ViewNameTooLong      = 25,

    #[display(fmt = "User unauthorized")]
    UserUnauthorized     = 100,

    #[display(fmt = "Workspace websocket error")]
    WsConnectError       = 200,

    #[display(fmt = "Server error")]
    InternalError        = 1000,
    #[display(fmt = "Record not found")]
    RecordNotFound       = 1001,
}

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}

impl ErrorCode {
    pub fn value(&self) -> i32 {
        let code: ProtoBufErrorCode = self.clone().try_into().unwrap();
        code.value()
    }

    pub fn from_i32(value: i32) -> Self {
        match ProtoBufErrorCode::from_i32(value) {
            None => ErrorCode::InternalError,
            Some(code) => ErrorCode::try_from(&code).unwrap(),
        }
    }
}
