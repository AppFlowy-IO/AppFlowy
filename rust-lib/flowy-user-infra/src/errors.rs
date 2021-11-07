use crate::protobuf::ErrorCode as ProtoBufErrorCode;
use derive_more::Display;
use flowy_derive::ProtoBuf_Enum;
use protobuf::ProtobufEnum;
use std::convert::{TryFrom, TryInto};

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "Email can not be empty or whitespace")]
    EmailIsEmpty       = 0,
    #[display(fmt = "Email format is not valid")]
    EmailFormatInvalid = 1,
    #[display(fmt = "Email already exists")]
    EmailAlreadyExists = 2,
    #[display(fmt = "Password can not be empty or whitespace")]
    PasswordIsEmpty    = 10,
    #[display(fmt = "Password format too long")]
    PasswordTooLong    = 11,
    #[display(fmt = "Password contains forbidden characters.")]
    PasswordContainsForbidCharacters = 12,
    #[display(fmt = "Password should contain a minimum of 6 characters with 1 special 1 letter and 1 numeric")]
    PasswordFormatInvalid = 13,
    #[display(fmt = "Password not match")]
    PasswordNotMatch   = 14,
    #[display(fmt = "User name is too long")]
    UserNameTooLong    = 20,
    #[display(fmt = "User name contain forbidden characters")]
    UserNameContainForbiddenCharacters = 21,
    #[display(fmt = "User name can not be empty or whitespace")]
    UserNameIsEmpty    = 22,
    #[display(fmt = "user id is empty or whitespace")]
    UserIdInvalid      = 23,
    #[display(fmt = "User token is invalid")]
    UserUnauthorized   = 24,
    #[display(fmt = "User not exist")]
    UserNotExist       = 25,

    #[display(fmt = "Server error")]
    ServerError        = 99,

    #[display(fmt = "Internal error")]
    InternalError      = 100,
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

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}
