use serde_repr::*;
use thiserror::Error;

use flowy_derive::ProtoBuf_Enum;

#[derive(Debug, Clone, PartialEq, Eq, Error, Serialize_repr, Deserialize_repr, ProtoBuf_Enum)]
#[repr(u8)]
pub enum ErrorCode {
  #[error("Internal error")]
  Internal = 0,

  #[error("Unauthorized user")]
  UserUnauthorized = 2,

  #[error("Record not found")]
  RecordNotFound = 3,

  #[error("User id is empty")]
  UserIdIsEmpty = 4,

  #[error("Workspace name can not be empty or whitespace")]
  WorkspaceNameInvalid = 5,

  #[error("Workspace id can not be empty or whitespace")]
  WorkspaceIdInvalid = 6,

  #[error("Color style of the App is invalid")]
  AppColorStyleInvalid = 7,

  #[error("Workspace desc is invalid")]
  WorkspaceDescTooLong = 8,

  #[error("Workspace description too long")]
  WorkspaceNameTooLong = 9,

  #[error("App id can not be empty or whitespace")]
  AppIdInvalid = 10,

  #[error("App name can not be empty or whitespace")]
  AppNameInvalid = 11,

  #[error("View name can not be empty or whitespace")]
  ViewNameInvalid = 12,

  #[error("Thumbnail of the view is invalid")]
  ViewThumbnailInvalid = 13,

  #[error("View id can not be empty or whitespace")]
  ViewIdIsInvalid = 14,

  #[error("View desc too long")]
  ViewDescTooLong = 15,

  #[error("View data is invalid")]
  ViewDataInvalid = 16,

  #[error("View name too long")]
  ViewNameTooLong = 17,

  #[error("Http server connection error")]
  HttpServerConnectError = 18,

  #[error("Email can not be empty or whitespace")]
  EmailIsEmpty = 19,

  #[error("Email format is not valid")]
  EmailFormatInvalid = 20,

  #[error("Email already exists")]
  EmailAlreadyExists = 21,

  #[error("Password can not be empty or whitespace")]
  PasswordIsEmpty = 22,

  #[error("Password format too long")]
  PasswordTooLong = 23,

  #[error("Password contains forbidden characters.")]
  PasswordContainsForbidCharacters = 24,

  #[error(
    "Password should contain a minimum of 6 characters with 1 special 1 letter and 1 numeric"
  )]
  PasswordFormatInvalid = 25,

  #[error("Password not match")]
  PasswordNotMatch = 26,

  #[error("User name is too long")]
  UserNameTooLong = 27,

  #[error("User name contain forbidden characters")]
  UserNameContainForbiddenCharacters = 28,

  #[error("User name can not be empty or whitespace")]
  UserNameIsEmpty = 29,

  #[error("user id is empty or whitespace")]
  UserIdInvalid = 30,

  #[error("User not exist")]
  UserNotExist = 31,

  #[error("Text is too long")]
  TextTooLong = 32,

  #[error("Database id is empty")]
  DatabaseIdIsEmpty = 33,

  #[error("Grid view id is empty")]
  DatabaseViewIdIsEmpty = 34,

  #[error("Grid block id is empty")]
  BlockIdIsEmpty = 35,

  #[error("Row id is empty")]
  RowIdIsEmpty = 36,

  #[error("Select option id is empty")]
  OptionIdIsEmpty = 37,

  #[error("Field id is empty")]
  FieldIdIsEmpty = 38,

  #[error("Field doesn't exist")]
  FieldDoesNotExist = 39,

  #[error("The name of the option should not be empty")]
  SelectOptionNameIsEmpty = 40,

  #[error("Field not exists")]
  FieldNotExists = 41,

  #[error("The operation in this field is invalid")]
  FieldInvalidOperation = 42,

  #[error("Filter id is empty")]
  FilterIdIsEmpty = 43,

  #[error("Field is not exist")]
  FieldRecordNotFound = 44,

  #[error("Field's type-option data should not be empty")]
  TypeOptionDataIsEmpty = 45,

  #[error("Group id is empty")]
  GroupIdIsEmpty = 46,

  #[error("Invalid date time format")]
  InvalidDateTimeFormat = 47,

  #[error("Invalid data")]
  InvalidData = 49,

  #[error("Serde")]
  Serde = 50,

  #[error("Protobuf serde")]
  ProtobufSerde = 51,

  #[error("Out of bounds")]
  OutOfBounds = 52,

  #[error("Sort id is empty")]
  SortIdIsEmpty = 53,

  #[error("Connect refused")]
  ConnectRefused = 54,

  #[error("Connection timeout")]
  ConnectTimeout = 55,

  #[error("Connection closed")]
  ConnectClose = 56,

  #[error("Connection canceled")]
  ConnectCancel = 57,

  #[error("Sql error")]
  SqlError = 58,

  #[error("Http request error")]
  HttpError = 59,

  #[error("The content should not be empty")]
  UnexpectedEmpty = 60,

  #[error("Only the date type can be used in calendar")]
  UnexpectedCalendarFieldType = 61,

  #[error("Document Data Invalid")]
  DocumentDataInvalid = 62,

  #[error("Unsupported auth type")]
  UnsupportedAuthType = 63,

  #[error("Invalid auth configuration")]
  InvalidAuthConfig = 64,

  #[error("Missing auth field")]
  MissingAuthField = 65,

  #[error("Only one application can access the database")]
  MultipleDBInstance = 66,

  #[error("Document id is empty")]
  DocumentIdIsEmpty = 67,

  #[error("Apply actions is empty")]
  ApplyActionsIsEmpty = 68,
}

impl ErrorCode {
  pub fn value(&self) -> i32 {
    self.clone() as i32
  }
}
