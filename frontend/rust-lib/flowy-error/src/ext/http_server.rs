use crate::FlowyError;
use flowy_error_code::ErrorCode;
use http_flowy::errors::{ErrorCode as ServerErrorCode, ServerError};

impl std::convert::From<ServerError> for FlowyError {
    fn from(error: ServerError) -> Self {
        let code = server_error_to_flowy_error(error.code);
        FlowyError::new(code, &error.msg)
    }
}

fn server_error_to_flowy_error(code: ServerErrorCode) -> ErrorCode {
    match code {
        ServerErrorCode::UserUnauthorized => ErrorCode::UserUnauthorized,
        ServerErrorCode::PasswordNotMatch => ErrorCode::PasswordNotMatch,
        ServerErrorCode::RecordNotFound => ErrorCode::RecordNotFound,
        ServerErrorCode::ConnectRefused | ServerErrorCode::ConnectTimeout | ServerErrorCode::ConnectClose => {
            ErrorCode::HttpServerConnectError
        }
        _ => ErrorCode::Internal,
    }
}
