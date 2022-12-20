use crate::protobuf::ErrorCode as ProtoBufErrorCode;
use flowy_derive::ProtoBuf_Enum;
use protobuf::ProtobufEnum;
use thiserror::Error;
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, PartialEq, Eq, Error)]
pub enum ErrorCode {
    #[error("Internal error")]
    Internal = 0,

    #[error("UserUnauthorized")]
    UserUnauthorized = 2,

    #[error("RecordNotFound")]
    RecordNotFound = 3,

    #[error("User id is empty")]
    UserIdIsEmpty = 4,

    #[error("Workspace name can not be empty or whitespace")]
    WorkspaceNameInvalid = 100,

    #[error("Workspace id can not be empty or whitespace")]
    WorkspaceIdInvalid = 101,

    #[error("Color style of the App is invalid")]
    AppColorStyleInvalid = 102,

    #[error("Workspace desc is invalid")]
    WorkspaceDescTooLong = 103,

    #[error("Workspace description too long")]
    WorkspaceNameTooLong = 104,

    #[error("App id can not be empty or whitespace")]
    AppIdInvalid = 110,

    #[error("App name can not be empty or whitespace")]
    AppNameInvalid = 111,

    #[error("View name can not be empty or whitespace")]
    ViewNameInvalid = 120,

    #[error("Thumbnail of the view is invalid")]
    ViewThumbnailInvalid = 121,

    #[error("View id can not be empty or whitespace")]
    ViewIdInvalid = 122,

    #[error("View desc too long")]
    ViewDescTooLong = 123,

    #[error("View data is invalid")]
    ViewDataInvalid = 124,

    #[error("View name too long")]
    ViewNameTooLong = 125,

    #[error("Connection error")]
    ConnectError = 200,

    #[error("Email can not be empty or whitespace")]
    EmailIsEmpty = 300,
    #[error("Email format is not valid")]
    EmailFormatInvalid = 301,
    #[error("Email already exists")]
    EmailAlreadyExists = 302,
    #[error("Password can not be empty or whitespace")]
    PasswordIsEmpty = 303,
    #[error("Password format too long")]
    PasswordTooLong = 304,
    #[error("Password contains forbidden characters.")]
    PasswordContainsForbidCharacters = 305,
    #[error("Password should contain a minimum of 6 characters with 1 special 1 letter and 1 numeric")]
    PasswordFormatInvalid = 306,
    #[error("Password not match")]
    PasswordNotMatch = 307,
    #[error("User name is too long")]
    UserNameTooLong = 308,
    #[error("User name contain forbidden characters")]
    UserNameContainForbiddenCharacters = 309,
    #[error("User name can not be empty or whitespace")]
    UserNameIsEmpty = 310,
    #[error("user id is empty or whitespace")]
    UserIdInvalid = 311,
    #[error("User not exist")]
    UserNotExist = 312,
    #[error("Text is too long")]
    TextTooLong = 400,

    #[error("Grid id is empty")]
    GridIdIsEmpty = 410,
    #[error("Grid view id is empty")]
    GridViewIdIsEmpty = 411,

    #[error("Grid block id is empty")]
    BlockIdIsEmpty = 420,
    #[error("Row id is empty")]
    RowIdIsEmpty = 430,
    #[error("Select option id is empty")]
    OptionIdIsEmpty = 431,
    #[error("Field id is empty")]
    FieldIdIsEmpty = 440,
    #[error("Field doesn't exist")]
    FieldDoesNotExist = 441,
    #[error("The name of the option should not be empty")]
    SelectOptionNameIsEmpty = 442,
    #[error("Field not exists")]
    FieldNotExists = 443,
    #[error("The operation in this field is invalid")]
    FieldInvalidOperation = 444,
    #[error("Filter id is empty")]
    FilterIdIsEmpty = 445,
    #[display(fmt = "Field is not exist")]
    FieldRecordNotFound = 446,

    #[error("Field's type-option data should not be empty")]
    TypeOptionDataIsEmpty = 450,

    #[error("Group id is empty")]
    GroupIdIsEmpty = 460,

    #[error("Invalid date time format")]
    InvalidDateTimeFormat = 500,

    #[error("The input string is empty or contains invalid characters")]
    UnexpectedEmptyString = 999,

    #[error("Invalid data")]
    InvalidData = 1000,

    #[error("Serde")]
    Serde = 1001,

    #[error("Protobuf serde")]
    ProtobufSerde = 1002,

    #[error("Out of bounds")]
    OutOfBounds = 10001,
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
