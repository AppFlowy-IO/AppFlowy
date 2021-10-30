use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use flowy_document::errors::DocError;
use flowy_net::errors::ErrorCode as ServerErrorCode;
use std::{convert::TryInto, fmt, fmt::Debug};

pub type WorkspaceResult<T> = std::result::Result<T, WorkspaceError>;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct WorkspaceError {
    #[pb(index = 1)]
    pub code: ErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

macro_rules! static_workspace_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> WorkspaceError {
            WorkspaceError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

impl WorkspaceError {
    pub fn new(code: ErrorCode, msg: &str) -> Self {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }

    static_workspace_error!(workspace_name, ErrorCode::WorkspaceNameInvalid);
    static_workspace_error!(workspace_id, ErrorCode::WorkspaceIdInvalid);
    static_workspace_error!(color_style, ErrorCode::AppColorStyleInvalid);
    static_workspace_error!(workspace_desc, ErrorCode::WorkspaceDescInvalid);
    static_workspace_error!(app_name, ErrorCode::AppNameInvalid);
    static_workspace_error!(invalid_app_id, ErrorCode::AppIdInvalid);
    static_workspace_error!(view_name, ErrorCode::ViewNameInvalid);
    static_workspace_error!(view_thumbnail, ErrorCode::ViewThumbnailInvalid);
    static_workspace_error!(invalid_view_id, ErrorCode::ViewIdInvalid);
    static_workspace_error!(view_desc, ErrorCode::ViewDescInvalid);
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

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "Workspace name is invalid")]
    WorkspaceNameInvalid = 0,

    #[display(fmt = "Workspace id is invalid")]
    WorkspaceIdInvalid   = 1,

    #[display(fmt = "Color style of the App is invalid")]
    AppColorStyleInvalid = 2,

    #[display(fmt = "Workspace desc is invalid")]
    WorkspaceDescInvalid = 3,

    #[display(fmt = "Id of the App  is invalid")]
    AppIdInvalid         = 10,

    #[display(fmt = "Name of the App  is invalid")]
    AppNameInvalid       = 11,

    #[display(fmt = "Name of the View  is invalid")]
    ViewNameInvalid      = 20,

    #[display(fmt = "Thumbnail of the view is invalid")]
    ViewThumbnailInvalid = 21,

    #[display(fmt = "Id of the View is invalid")]
    ViewIdInvalid        = 22,

    #[display(fmt = "Description of the View is invalid")]
    ViewDescInvalid      = 23,

    #[display(fmt = "View data is invalid")]
    ViewDataInvalid      = 24,

    #[display(fmt = "User unauthorized")]
    UserUnauthorized     = 100,

    #[display(fmt = "Workspace websocket error")]
    WsConnectError       = 200,

    #[display(fmt = "Server error")]
    InternalError        = 1000,
    #[display(fmt = "Record not found")]
    RecordNotFound       = 1001,
}

pub fn internal_error<T>(e: T) -> WorkspaceError
where
    T: std::fmt::Debug,
{
    WorkspaceError::internal().context(e)
}

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}

impl std::convert::From<flowy_document::errors::DocError> for WorkspaceError {
    fn from(error: DocError) -> Self { WorkspaceError::internal().context(error) }
}

impl std::convert::From<flowy_net::errors::ServerError> for WorkspaceError {
    fn from(error: flowy_net::errors::ServerError) -> Self {
        let code = server_error_to_workspace_error(error.code);
        WorkspaceError::new(code, &error.msg)
    }
}

impl std::convert::From<flowy_database::Error> for WorkspaceError {
    fn from(error: flowy_database::Error) -> Self { WorkspaceError::internal().context(error) }
}

impl flowy_dispatch::Error for WorkspaceError {
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
