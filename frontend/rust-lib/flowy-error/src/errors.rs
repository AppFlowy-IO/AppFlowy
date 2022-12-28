use anyhow::Result;
use bytes::Bytes;
use flowy_derive::ProtoBuf;
use flowy_error_code::ErrorCode;
use lib_dispatch::prelude::{AFPluginEventResponse, ResponseBuilder};
use std::{convert::TryInto, fmt::Debug};
use thiserror::Error;

pub type FlowyResult<T> = anyhow::Result<T, FlowyError>;

#[derive(Debug, Default, Clone, ProtoBuf, Error)]
#[error("{code:?}: {msg}")]
pub struct FlowyError {
    #[pb(index = 1)]
    pub code: i32,

    #[pb(index = 2)]
    pub msg: String,
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
    pub fn new(code: ErrorCode, msg: &str) -> Self {
        Self {
            code: code.value(),
            msg: msg.to_owned(),
        }
    }
    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    static_flowy_error!(internal, ErrorCode::Internal);
    static_flowy_error!(record_not_found, ErrorCode::RecordNotFound);
    static_flowy_error!(workspace_name, ErrorCode::WorkspaceNameInvalid);
    static_flowy_error!(workspace_id, ErrorCode::WorkspaceIdInvalid);
    static_flowy_error!(color_style, ErrorCode::AppColorStyleInvalid);
    static_flowy_error!(workspace_desc, ErrorCode::WorkspaceDescTooLong);
    static_flowy_error!(app_name, ErrorCode::AppNameInvalid);
    static_flowy_error!(invalid_app_id, ErrorCode::AppIdInvalid);
    static_flowy_error!(view_name, ErrorCode::ViewNameInvalid);
    static_flowy_error!(view_thumbnail, ErrorCode::ViewThumbnailInvalid);
    static_flowy_error!(invalid_view_id, ErrorCode::ViewIdInvalid);
    static_flowy_error!(view_desc, ErrorCode::ViewDescTooLong);
    static_flowy_error!(view_data, ErrorCode::ViewDataInvalid);
    static_flowy_error!(unauthorized, ErrorCode::UserUnauthorized);
    static_flowy_error!(connection, ErrorCode::HttpServerConnectError);
    static_flowy_error!(email_empty, ErrorCode::EmailIsEmpty);
    static_flowy_error!(email_format, ErrorCode::EmailFormatInvalid);
    static_flowy_error!(email_exist, ErrorCode::EmailAlreadyExists);
    static_flowy_error!(password_empty, ErrorCode::PasswordIsEmpty);
    static_flowy_error!(passworkd_too_long, ErrorCode::PasswordTooLong);
    static_flowy_error!(password_forbid_char, ErrorCode::PasswordContainsForbidCharacters);
    static_flowy_error!(password_format, ErrorCode::PasswordFormatInvalid);
    static_flowy_error!(password_not_match, ErrorCode::PasswordNotMatch);
    static_flowy_error!(name_too_long, ErrorCode::UserNameTooLong);
    static_flowy_error!(name_forbid_char, ErrorCode::UserNameContainForbiddenCharacters);
    static_flowy_error!(name_empty, ErrorCode::UserNameIsEmpty);
    static_flowy_error!(user_id, ErrorCode::UserIdInvalid);
    static_flowy_error!(user_not_exist, ErrorCode::UserNotExist);
    static_flowy_error!(text_too_long, ErrorCode::TextTooLong);
    static_flowy_error!(invalid_data, ErrorCode::InvalidData);
    static_flowy_error!(out_of_bounds, ErrorCode::OutOfBounds);
    static_flowy_error!(serde, ErrorCode::Serde);
    static_flowy_error!(field_record_not_found, ErrorCode::FieldRecordNotFound);
}

impl std::convert::From<ErrorCode> for FlowyError {
    fn from(code: ErrorCode) -> Self {
        FlowyError {
            code: code.value(),
            msg: format!("{}", code),
        }
    }
}

pub fn internal_error<T>(e: T) -> FlowyError
where
    T: std::fmt::Debug,
{
    FlowyError::internal().context(e)
}

// Not needed because of thiserror derive macro
/* impl fmt::Display for FlowyError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{:?}: {}", &self.code, &self.msg)
    }
}
 */
impl lib_dispatch::Error for FlowyError {
    fn as_response(&self) -> AFPluginEventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();

        println!("Serialize FlowyError: {:?} to event response", self);
        ResponseBuilder::Err().data(bytes).build()
    }
}

impl std::convert::From<std::io::Error> for FlowyError {
    fn from(error: std::io::Error) -> Self {
        FlowyError::internal().context(error)
    }
}

impl std::convert::From<protobuf::ProtobufError> for FlowyError {
    fn from(e: protobuf::ProtobufError) -> Self {
        FlowyError::internal().context(e)
    }
}

//impl std::error::Error for FlowyError {}
