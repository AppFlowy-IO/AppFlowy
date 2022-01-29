use crate::FlowyError;
use backend_service::errors::{ErrorCode as ServerErrorCode, ServerError};
use error_code::ErrorCode;

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
            ErrorCode::ConnectError
        }
        _ => ErrorCode::Internal,
    }
}
