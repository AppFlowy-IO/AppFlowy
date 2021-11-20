use bytes::Bytes;

use backend_service::errors::ErrorCode as ServerErrorCode;
use flowy_derive::ProtoBuf;
use flowy_document::errors::DocError;
pub use flowy_workspace_infra::errors::ErrorCode;
use lib_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::{convert::TryInto, fmt, fmt::Debug};

pub type WorkspaceResult<T> = std::result::Result<T, WorkspaceError>;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct WorkspaceError {
    #[pb(index = 1)]
    pub code: i32,

    #[pb(index = 2)]
    pub msg: String,
}

macro_rules! static_workspace_error {
    ($name:ident, $code:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> WorkspaceError { $code.into() }
    };
}

impl WorkspaceError {
    pub fn new(code: ErrorCode, msg: &str) -> Self {
        Self {
            code: code.value(),
            msg: msg.to_owned(),
        }
    }

    static_workspace_error!(workspace_name, ErrorCode::WorkspaceNameInvalid);
    static_workspace_error!(workspace_id, ErrorCode::WorkspaceIdInvalid);
    static_workspace_error!(color_style, ErrorCode::AppColorStyleInvalid);
    static_workspace_error!(workspace_desc, ErrorCode::WorkspaceDescTooLong);
    static_workspace_error!(app_name, ErrorCode::AppNameInvalid);
    static_workspace_error!(invalid_app_id, ErrorCode::AppIdInvalid);
    static_workspace_error!(view_name, ErrorCode::ViewNameInvalid);
    static_workspace_error!(view_thumbnail, ErrorCode::ViewThumbnailInvalid);
    static_workspace_error!(invalid_view_id, ErrorCode::ViewIdInvalid);
    static_workspace_error!(view_desc, ErrorCode::ViewDescTooLong);
    static_workspace_error!(view_data, ErrorCode::ViewDataInvalid);
    static_workspace_error!(unauthorized, ErrorCode::UserUnauthorized);
    static_workspace_error!(internal, ErrorCode::InternalError);
    static_workspace_error!(record_not_found, ErrorCode::RecordNotFound);
    static_workspace_error!(ws, ErrorCode::WsConnectError);

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }
}

pub fn internal_error<T>(e: T) -> WorkspaceError
where
    T: std::fmt::Debug,
{
    WorkspaceError::internal().context(e)
}

impl std::convert::From<ErrorCode> for WorkspaceError {
    fn from(code: ErrorCode) -> Self {
        WorkspaceError {
            code: code.value(),
            msg: format!("{}", code),
        }
    }
}

impl std::convert::From<flowy_document::errors::DocError> for WorkspaceError {
    fn from(error: DocError) -> Self { WorkspaceError::internal().context(error) }
}

impl std::convert::From<backend_service::errors::ServerError> for WorkspaceError {
    fn from(error: backend_service::errors::ServerError) -> Self {
        let code = server_error_to_workspace_error(error.code);
        WorkspaceError::new(code, &error.msg)
    }
}

impl std::convert::From<flowy_database::Error> for WorkspaceError {
    fn from(error: flowy_database::Error) -> Self { WorkspaceError::internal().context(error) }
}

impl lib_dispatch::Error for WorkspaceError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

impl fmt::Display for WorkspaceError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}: {}", &self.code, &self.msg) }
}

fn server_error_to_workspace_error(code: ServerErrorCode) -> ErrorCode {
    match code {
        ServerErrorCode::UserUnauthorized => ErrorCode::UserUnauthorized,
        ServerErrorCode::RecordNotFound => ErrorCode::RecordNotFound,
        _ => ErrorCode::InternalError,
    }
}
