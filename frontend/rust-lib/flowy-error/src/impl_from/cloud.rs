use client_api::error::{AppResponseError, ErrorCode as AppErrorCode};

use crate::{ErrorCode, FlowyError};

impl From<AppResponseError> for FlowyError {
  fn from(error: AppResponseError) -> Self {
    let code = match error.code {
      AppErrorCode::Ok => ErrorCode::Internal,
      AppErrorCode::Unhandled => ErrorCode::Internal,
      AppErrorCode::RecordNotFound => ErrorCode::RecordNotFound,
      AppErrorCode::RecordAlreadyExists => ErrorCode::RecordAlreadyExists,
      AppErrorCode::InvalidEmail => ErrorCode::EmailFormatInvalid,
      AppErrorCode::InvalidPassword => ErrorCode::PasswordFormatInvalid,
      AppErrorCode::OAuthError => ErrorCode::UserUnauthorized,
      AppErrorCode::MissingPayload => ErrorCode::MissingPayload,
      AppErrorCode::OpenError => ErrorCode::Internal,
      AppErrorCode::InvalidUrl => ErrorCode::InvalidURL,
      AppErrorCode::InvalidRequest => ErrorCode::InvalidParams,
      AppErrorCode::InvalidOAuthProvider => ErrorCode::InvalidAuthConfig,
      AppErrorCode::NotLoggedIn => ErrorCode::UserUnauthorized,
      AppErrorCode::NotEnoughPermissions => ErrorCode::NotEnoughPermissions,
      AppErrorCode::NetworkError => ErrorCode::HttpError,
      AppErrorCode::PayloadTooLarge => ErrorCode::CloudRequestPayloadTooLarge,
      AppErrorCode::UserUnAuthorized => match &*error.message {
        "Workspace Limit Exceeded" => ErrorCode::WorkspaceLimitExceeded,
        "Workspace Member Limit Exceeded" => ErrorCode::WorkspaceMemberLimitExceeded,
        _ => ErrorCode::UserUnauthorized,
      },
      _ => ErrorCode::Internal,
    };

    FlowyError::new(code, error.message)
  }
}
