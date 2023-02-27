use crate::code::ErrorCode;
use user_model::errors::UserErrorCode;

impl std::convert::From<UserErrorCode> for ErrorCode {
  fn from(code: UserErrorCode) -> Self {
    match code {
      UserErrorCode::Internal => ErrorCode::Internal,
      UserErrorCode::WorkspaceIdInvalid => ErrorCode::WorkspaceIdInvalid,
      UserErrorCode::EmailIsEmpty => ErrorCode::EmailIsEmpty,
      UserErrorCode::EmailFormatInvalid => ErrorCode::EmailFormatInvalid,
      UserErrorCode::UserIdInvalid => ErrorCode::UserIdInvalid,
      UserErrorCode::UserNameContainForbiddenCharacters => {
        ErrorCode::UserNameContainForbiddenCharacters
      },
      UserErrorCode::UserNameIsEmpty => ErrorCode::UserNameIsEmpty,
      UserErrorCode::UserNotExist => ErrorCode::UserNotExist,
      UserErrorCode::PasswordIsEmpty => ErrorCode::PasswordIsEmpty,
      UserErrorCode::PasswordTooLong => ErrorCode::PasswordTooLong,
      UserErrorCode::PasswordContainsForbidCharacters => {
        ErrorCode::PasswordContainsForbidCharacters
      },
      UserErrorCode::PasswordFormatInvalid => ErrorCode::PasswordFormatInvalid,
      UserErrorCode::PasswordNotMatch => ErrorCode::PasswordNotMatch,
      UserErrorCode::UserNameTooLong => ErrorCode::UserNameTooLong,
    }
  }
}
