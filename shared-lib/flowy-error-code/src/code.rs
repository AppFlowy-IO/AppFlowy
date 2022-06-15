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

    #[display(fmt = "User id is empty")]
    UserIdIsEmpty = 4,

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
    #[display(fmt = "Text is too long")]
    TextTooLong = 400,

    #[display(fmt = "Grid id is empty")]
    GridIdIsEmpty = 410,
    #[display(fmt = "Grid block id is empty")]
    BlockIdIsEmpty = 420,
    #[display(fmt = "Row id is empty")]
    RowIdIsEmpty = 430,
    #[display(fmt = "Select option id is empty")]
    OptionIdIsEmpty = 431,
    #[display(fmt = "Field id is empty")]
    FieldIdIsEmpty = 440,
    #[display(fmt = "Field doesn't exist")]
    FieldDoesNotExist = 441,
    #[display(fmt = "The name of the option should not be empty")]
    SelectOptionNameIsEmpty = 442,
    #[display(fmt = "Field not exists")]
    FieldNotExists = 443,
    #[display(fmt = "The operation in this field is invalid")]
    FieldInvalidOperation = 444,

    #[display(fmt = "Field's type option data should not be empty")]
    TypeOptionDataIsEmpty = 450,

    #[display(fmt = "Invalid date time format")]
    InvalidDateTimeFormat = 500,

    #[display(fmt = "The input string is empty or contains invalid characters")]
    UnexpectedEmptyString = 999,

    #[display(fmt = "Invalid data")]
    InvalidData = 1000,
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
