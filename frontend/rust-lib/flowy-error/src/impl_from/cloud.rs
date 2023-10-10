use client_api::error::AppError;

use crate::{ErrorCode, FlowyError};

impl From<AppError> for FlowyError {
  fn from(error: AppError) -> Self {
    let code = match error.code {
      client_api::error::ErrorCode::Ok => ErrorCode::Internal,
      client_api::error::ErrorCode::Unhandled => ErrorCode::Internal,
      client_api::error::ErrorCode::RecordNotFound => ErrorCode::RecordNotFound,
      client_api::error::ErrorCode::FileNotFound => ErrorCode::RecordNotFound,
      client_api::error::ErrorCode::RecordAlreadyExists => ErrorCode::RecordAlreadyExists,
      client_api::error::ErrorCode::InvalidEmail => ErrorCode::EmailFormatInvalid,
      client_api::error::ErrorCode::InvalidPassword => ErrorCode::PasswordFormatInvalid,
      client_api::error::ErrorCode::OAuthError => ErrorCode::UserUnauthorized,
      client_api::error::ErrorCode::MissingPayload => ErrorCode::MissingPayload,
      client_api::error::ErrorCode::OpenError => ErrorCode::Internal,
      client_api::error::ErrorCode::InvalidUrl => ErrorCode::InvalidURL,
      client_api::error::ErrorCode::InvalidRequestParams => ErrorCode::InvalidParams,
      client_api::error::ErrorCode::UrlMissingParameter => ErrorCode::InvalidParams,
      client_api::error::ErrorCode::InvalidOAuthProvider => ErrorCode::InvalidAuthConfig,
      client_api::error::ErrorCode::NotLoggedIn => ErrorCode::UserUnauthorized,
      client_api::error::ErrorCode::NotEnoughPermissions => ErrorCode::NotEnoughPermissions,
      client_api::error::ErrorCode::UserNameIsEmpty => ErrorCode::UserNameIsEmpty,
      _ => ErrorCode::Internal,
    };

    FlowyError::new(code, error.message)
  }
}
