use crate::protobuf::ErrorCode as ProtoBufErrorCode;
use derive_more::Display;
use flowy_derive::ProtoBuf_Enum;
use protobuf::ProtobufEnum;
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "Internal error")]
    Internal = 0,

    #[display(fmt = "UserUnauthorized")]
    UserUnauthorized = 2,

    #[display(fmt = "RecordNotFound")]
    RecordNotFound = 3,

    #[display(fmt = "Workspace name can not be empty or whitespace")]
    WorkspaceNameInvalid = 100,

    #[display(fmt = "Workspace id can not be empty or whitespace")]
    WorkspaceIdInvalid = 101,

    #[display(fmt = "Color style of the App is invalid")]
    AppColorStyleInvalid = 102,

    #[display(fmt = "Workspace desc is invalid")]
    WorkspaceDescTooLong = 103,

    #[display(fmt = "Workspace description too long")]
    WorkspaceNameTooLong = 104,

    #[display(fmt = "App id can not be empty or whitespace")]
    AppIdInvalid = 110,

    #[display(fmt = "App name can not be empty or whitespace")]
    AppNameInvalid = 111,

    #[display(fmt = "View name can not be empty or whitespace")]
    ViewNameInvalid = 120,

    #[display(fmt = "Thumbnail of the view is invalid")]
    ViewThumbnailInvalid = 121,

    #[display(fmt = "View id can not be empty or whitespace")]
    ViewIdInvalid = 122,

    #[display(fmt = "View desc too long")]
    ViewDescTooLong = 123,

    #[display(fmt = "View data is invalid")]
    ViewDataInvalid = 124,

    #[display(fmt = "View name too long")]
    ViewNameTooLong = 125,

    #[display(fmt = "Connection error")]
    ConnectError = 200,

    #[display(fmt = "Email can not be empty or whitespace")]
    EmailIsEmpty = 300,
    #[display(fmt = "Email format is not valid")]
    EmailFormatInvalid = 301,
    #[display(fmt = "Email already exists")]
    EmailAlreadyExists = 302,
    #[display(fmt = "Password can not be empty or whitespace")]
    PasswordIsEmpty = 303,
    #[display(fmt = "Password format too long")]
    PasswordTooLong = 304,
    #[display(fmt = "Password contains forbidden characters.")]
    PasswordContainsForbidCharacters = 305,
    #[display(fmt = "Password should contain a minimum of 6 characters with 1 special 1 letter and 1 numeric")]
    PasswordFormatInvalid = 306,
    #[display(fmt = "Password not match")]
    PasswordNotMatch = 307,
    #[display(fmt = "User name is too long")]
    UserNameTooLong = 308,
    #[display(fmt = "User name contain forbidden characters")]
    UserNameContainForbiddenCharacters = 309,
    #[display(fmt = "User name can not be empty or whitespace")]
    UserNameIsEmpty = 310,
    #[display(fmt = "user id is empty or whitespace")]
    UserIdInvalid = 311,
    #[display(fmt = "User not exist")]
    UserNotExist = 312,
}

impl ErrorCode {
    pub fn value(&self) -> i32 {
        let code: ProtoBufErrorCode = self.clone().try_into().unwrap();
        code.value()
    }

    pub fn from_i32(value: i32) -> Self {
        match ProtoBufErrorCode::from_i32(value) {
            None => ErrorCode::Internal,
            Some(code) => ErrorCode::try_from(&code).unwrap(),
        }
    }
}
