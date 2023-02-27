use crate::code::ErrorCode;
use http_error_code::ErrorCode as ServerErrorCode;

impl std::convert::From<ServerErrorCode> for ErrorCode {
  fn from(code: ServerErrorCode) -> Self {
    match code {
      ServerErrorCode::UserUnauthorized => ErrorCode::UserUnauthorized,
      ServerErrorCode::PasswordNotMatch => ErrorCode::PasswordNotMatch,
      ServerErrorCode::RecordNotFound => ErrorCode::RecordNotFound,
      ServerErrorCode::ConnectRefused
      | ServerErrorCode::ConnectTimeout
      | ServerErrorCode::ConnectClose => ErrorCode::HttpServerConnectError,
      _ => ErrorCode::Internal,
    }
  }
}
