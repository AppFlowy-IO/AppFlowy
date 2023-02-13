use serde_repr::*;
use thiserror::Error;

#[derive(Debug, Clone, PartialEq, Eq, Error, Serialize_repr, Deserialize_repr)]
#[repr(u8)]
pub enum UserErrorCode {
  #[error("Internal error")]
  Internal = 0,

  #[error("Workspace id can not be empty or whitespace")]
  WorkspaceIdInvalid = 1,

  #[error("Email can not be empty or whitespace")]
  EmailIsEmpty = 2,

  #[error("Email format is not valid")]
  EmailFormatInvalid = 3,

  #[error("user id is empty or whitespace")]
  UserIdInvalid = 4,

  #[error("User name contain forbidden characters")]
  UserNameContainForbiddenCharacters = 5,

  #[error("User name can not be empty or whitespace")]
  UserNameIsEmpty = 6,

  #[error("User not exist")]
  UserNotExist = 7,

  #[error("Password can not be empty or whitespace")]
  PasswordIsEmpty = 8,

  #[error("Password format too long")]
  PasswordTooLong = 9,

  #[error("Password contains forbidden characters.")]
  PasswordContainsForbidCharacters = 10,

  #[error(
    "Password should contain a minimum of 6 characters with 1 special 1 letter and 1 numeric"
  )]
  PasswordFormatInvalid = 11,

  #[error("Password not match")]
  PasswordNotMatch = 12,

  #[error("User name is too long")]
  UserNameTooLong = 13,
}
