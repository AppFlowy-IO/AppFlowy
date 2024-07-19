use std::convert::TryInto;
use std::fmt::{Debug, Display};

use protobuf::ProtobufError;
use thiserror::Error;
use tokio::task::JoinError;
use validator::{ValidationError, ValidationErrors};

use flowy_derive::ProtoBuf;

use crate::code::ErrorCode;

pub type FlowyResult<T> = anyhow::Result<T, FlowyError>;

#[derive(Debug, Default, Clone, ProtoBuf, Error)]
#[error("{code:?}: {msg}")]
pub struct FlowyError {
  #[pb(index = 1)]
  pub code: ErrorCode,

  #[pb(index = 2)]
  pub msg: String,

  #[pb(index = 3)]
  pub payload: Vec<u8>,
}

macro_rules! static_flowy_error {
  ($name:ident, $code:expr) => {
    #[allow(non_snake_case, missing_docs)]
    pub fn $name() -> FlowyError {
      $code.into()
    }
  };
}

impl FlowyError {
  pub fn new<T: ToString>(code: ErrorCode, msg: T) -> Self {
    Self {
      code,
      msg: msg.to_string(),
      payload: vec![],
    }
  }
  pub fn with_context<T: Display>(mut self, error: T) -> Self {
    self.msg = format!("{}", error);
    self
  }

  pub fn with_payload<T: TryInto<Vec<u8>, Error = ProtobufError>>(mut self, payload: T) -> Self {
    self.payload = payload.try_into().unwrap_or_default();
    self
  }

  pub fn is_record_not_found(&self) -> bool {
    self.code == ErrorCode::RecordNotFound
  }

  pub fn is_already_exists(&self) -> bool {
    self.code == ErrorCode::RecordAlreadyExists
  }

  pub fn is_unauthorized(&self) -> bool {
    self.code == ErrorCode::UserUnauthorized || self.code == ErrorCode::RecordNotFound
  }

  pub fn is_invalid_data(&self) -> bool {
    self.code == ErrorCode::InvalidParams
  }

  pub fn is_local_version_not_support(&self) -> bool {
    self.code == ErrorCode::LocalVersionNotSupport
  }

  pub fn is_file_limit_exceeded(&self) -> bool {
    self.code == ErrorCode::FileStorageLimitExceeded
  }

  pub fn is_ai_response_limit_exceeded(&self) -> bool {
    self.code == ErrorCode::AIResponseLimitExceeded
  }

  static_flowy_error!(internal, ErrorCode::Internal);
  static_flowy_error!(record_not_found, ErrorCode::RecordNotFound);
  static_flowy_error!(workspace_initialize, ErrorCode::WorkspaceInitializeError);
  static_flowy_error!(view_name, ErrorCode::ViewNameInvalid);
  static_flowy_error!(view_thumbnail, ErrorCode::ViewThumbnailInvalid);
  static_flowy_error!(invalid_view_id, ErrorCode::ViewIdIsInvalid);
  static_flowy_error!(view_data, ErrorCode::ViewDataInvalid);
  static_flowy_error!(unauthorized, ErrorCode::UserUnauthorized);
  static_flowy_error!(email_empty, ErrorCode::EmailIsEmpty);
  static_flowy_error!(email_format, ErrorCode::EmailFormatInvalid);
  static_flowy_error!(email_exist, ErrorCode::EmailAlreadyExists);
  static_flowy_error!(password_empty, ErrorCode::PasswordIsEmpty);
  static_flowy_error!(passworkd_too_long, ErrorCode::PasswordTooLong);
  static_flowy_error!(
    password_forbid_char,
    ErrorCode::PasswordContainsForbidCharacters
  );
  static_flowy_error!(password_format, ErrorCode::PasswordFormatInvalid);
  static_flowy_error!(password_not_match, ErrorCode::PasswordNotMatch);
  static_flowy_error!(name_too_long, ErrorCode::UserNameTooLong);
  static_flowy_error!(
    name_forbid_char,
    ErrorCode::UserNameContainForbiddenCharacters
  );
  static_flowy_error!(name_empty, ErrorCode::UserNameIsEmpty);
  static_flowy_error!(user_id, ErrorCode::UserIdInvalid);
  static_flowy_error!(text_too_long, ErrorCode::TextTooLong);
  static_flowy_error!(invalid_data, ErrorCode::InvalidParams);
  static_flowy_error!(out_of_bounds, ErrorCode::OutOfBounds);
  static_flowy_error!(serde, ErrorCode::Serde);
  static_flowy_error!(field_record_not_found, ErrorCode::FieldRecordNotFound);
  static_flowy_error!(payload_none, ErrorCode::UnexpectedEmpty);
  static_flowy_error!(http, ErrorCode::HttpError);
  static_flowy_error!(
    unexpect_calendar_field_type,
    ErrorCode::UnexpectedCalendarFieldType
  );
  static_flowy_error!(collab_not_sync, ErrorCode::CollabDataNotSync);
  static_flowy_error!(server_error, ErrorCode::InternalServerError);
  static_flowy_error!(not_support, ErrorCode::NotSupportYet);
  static_flowy_error!(local_version_not_support, ErrorCode::LocalVersionNotSupport);
  static_flowy_error!(
    folder_index_manager_unavailable,
    ErrorCode::FolderIndexManagerUnavailable
  );
  static_flowy_error!(workspace_data_not_match, ErrorCode::WorkspaceDataNotMatch);
  static_flowy_error!(local_ai, ErrorCode::LocalAIError);
  static_flowy_error!(local_ai_unavailable, ErrorCode::LocalAIUnavailable);
}

impl std::convert::From<ErrorCode> for FlowyError {
  fn from(code: ErrorCode) -> Self {
    let msg = format!("{}", code);
    FlowyError {
      code,
      msg,
      payload: vec![],
    }
  }
}

pub fn internal_error<T>(e: T) -> FlowyError
where
  T: std::fmt::Debug,
{
  FlowyError::internal().with_context(format!("{:?}", e))
}

impl std::convert::From<std::io::Error> for FlowyError {
  fn from(error: std::io::Error) -> Self {
    FlowyError::internal().with_context(error)
  }
}

impl std::convert::From<protobuf::ProtobufError> for FlowyError {
  fn from(e: protobuf::ProtobufError) -> Self {
    FlowyError::internal().with_context(e)
  }
}

impl From<ValidationError> for FlowyError {
  fn from(value: ValidationError) -> Self {
    FlowyError::new(ErrorCode::InvalidParams, value)
  }
}

impl From<ValidationErrors> for FlowyError {
  fn from(value: ValidationErrors) -> Self {
    FlowyError::new(ErrorCode::InvalidParams, value)
  }
}

impl From<anyhow::Error> for FlowyError {
  fn from(e: anyhow::Error) -> Self {
    e.downcast::<FlowyError>()
      .unwrap_or_else(|err| FlowyError::new(ErrorCode::Internal, err))
  }
}

impl From<fancy_regex::Error> for FlowyError {
  fn from(e: fancy_regex::Error) -> Self {
    FlowyError::internal().with_context(e)
  }
}

impl From<JoinError> for FlowyError {
  fn from(e: JoinError) -> Self {
    FlowyError::internal().with_context(e)
  }
}

impl From<tokio::sync::oneshot::error::RecvError> for FlowyError {
  fn from(e: tokio::sync::oneshot::error::RecvError) -> Self {
    FlowyError::internal().with_context(e)
  }
}

impl From<String> for FlowyError {
  fn from(e: String) -> Self {
    FlowyError::internal().with_context(e)
  }
}
