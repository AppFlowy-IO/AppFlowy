use std::convert::TryInto;
use std::fmt::Debug;

use protobuf::ProtobufError;
use thiserror::Error;
use tokio::task::JoinError;
use validator::{ValidationError, ValidationErrors};

use flowy_derive::ProtoBuf;

use crate::code::ErrorCode as AFErrorCode;

pub type FlowyResult<T> = anyhow::Result<T, FlowyError>;

#[derive(Debug, Default, Clone, ProtoBuf, Error)]
#[error("{code:?}: {msg}")]
pub struct FlowyError {
  #[pb(index = 1)]
  pub code: crate::code::ErrorCode,

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
  pub fn new<T: ToString>(code: AFErrorCode, msg: T) -> Self {
    Self {
      code,
      msg: msg.to_string(),
      payload: vec![],
    }
  }
  pub fn with_context<T: Debug>(mut self, error: T) -> Self {
    self.msg = format!("{:?}", error);
    self
  }

  pub fn with_payload<T: TryInto<Vec<u8>, Error = ProtobufError>>(mut self, payload: T) -> Self {
    self.payload = payload.try_into().unwrap_or_default();
    self
  }

  pub fn is_record_not_found(&self) -> bool {
    self.code == AFErrorCode::RecordNotFound
  }

  pub fn is_already_exists(&self) -> bool {
    self.code == AFErrorCode::RecordAlreadyExists
  }

  pub fn is_unauthorized(&self) -> bool {
    self.code == AFErrorCode::UserUnauthorized || self.code == AFErrorCode::RecordNotFound
  }

  pub fn is_local_version_not_support(&self) -> bool {
    self.code == AFErrorCode::LocalVersionNotSupport
  }

  static_flowy_error!(internal, AFErrorCode::Internal);
  static_flowy_error!(record_not_found, AFErrorCode::RecordNotFound);
  static_flowy_error!(workspace_name, AFErrorCode::WorkspaceNameInvalid);
  static_flowy_error!(workspace_id, AFErrorCode::WorkspaceIdInvalid);
  static_flowy_error!(color_style, AFErrorCode::AppColorStyleInvalid);
  static_flowy_error!(workspace_desc, AFErrorCode::WorkspaceDescTooLong);
  static_flowy_error!(app_name, AFErrorCode::AppNameInvalid);
  static_flowy_error!(invalid_app_id, AFErrorCode::AppIdInvalid);
  static_flowy_error!(view_name, AFErrorCode::ViewNameInvalid);
  static_flowy_error!(view_thumbnail, AFErrorCode::ViewThumbnailInvalid);
  static_flowy_error!(invalid_view_id, AFErrorCode::ViewIdIsInvalid);
  static_flowy_error!(view_desc, AFErrorCode::ViewDescTooLong);
  static_flowy_error!(view_data, AFErrorCode::ViewDataInvalid);
  static_flowy_error!(unauthorized, AFErrorCode::UserUnauthorized);
  static_flowy_error!(email_empty, AFErrorCode::EmailIsEmpty);
  static_flowy_error!(email_format, AFErrorCode::EmailFormatInvalid);
  static_flowy_error!(email_exist, AFErrorCode::EmailAlreadyExists);
  static_flowy_error!(password_empty, AFErrorCode::PasswordIsEmpty);
  static_flowy_error!(passworkd_too_long, AFErrorCode::PasswordTooLong);
  static_flowy_error!(
    password_forbid_char,
    AFErrorCode::PasswordContainsForbidCharacters
  );
  static_flowy_error!(password_format, AFErrorCode::PasswordFormatInvalid);
  static_flowy_error!(password_not_match, AFErrorCode::PasswordNotMatch);
  static_flowy_error!(name_too_long, AFErrorCode::UserNameTooLong);
  static_flowy_error!(
    name_forbid_char,
    AFErrorCode::UserNameContainForbiddenCharacters
  );
  static_flowy_error!(name_empty, AFErrorCode::UserNameIsEmpty);
  static_flowy_error!(user_id, AFErrorCode::UserIdInvalid);
  static_flowy_error!(text_too_long, AFErrorCode::TextTooLong);
  static_flowy_error!(invalid_data, AFErrorCode::InvalidParams);
  static_flowy_error!(out_of_bounds, AFErrorCode::OutOfBounds);
  static_flowy_error!(serde, AFErrorCode::Serde);
  static_flowy_error!(field_record_not_found, AFErrorCode::FieldRecordNotFound);
  static_flowy_error!(payload_none, AFErrorCode::UnexpectedEmpty);
  static_flowy_error!(http, AFErrorCode::HttpError);
  static_flowy_error!(
    unexpect_calendar_field_type,
    AFErrorCode::UnexpectedCalendarFieldType
  );
  static_flowy_error!(collab_not_sync, AFErrorCode::CollabDataNotSync);
  static_flowy_error!(server_error, AFErrorCode::InternalServerError);
  static_flowy_error!(not_support, AFErrorCode::NotSupportYet);
  static_flowy_error!(
    local_version_not_support,
    AFErrorCode::LocalVersionNotSupport
  );
}

impl std::convert::From<AFErrorCode> for FlowyError {
  fn from(code: AFErrorCode) -> Self {
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
  FlowyError::internal().with_context(e)
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
    FlowyError::new(AFErrorCode::InvalidParams, value)
  }
}

impl From<ValidationErrors> for FlowyError {
  fn from(value: ValidationErrors) -> Self {
    FlowyError::new(AFErrorCode::InvalidParams, value)
  }
}

impl From<anyhow::Error> for FlowyError {
  fn from(e: anyhow::Error) -> Self {
    e.downcast::<FlowyError>()
      .unwrap_or_else(|err| FlowyError::new(AFErrorCode::Internal, err))
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
