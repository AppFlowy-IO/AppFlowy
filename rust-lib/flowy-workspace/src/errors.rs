use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::convert::TryInto;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct WorkspaceError {
    #[pb(index = 1)]
    pub code: WsErrCode,

    #[pb(index = 2)]
    pub msg: String,
}

impl WorkspaceError {
    pub fn new(code: WsErrCode, msg: &str) -> Self {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum WsErrCode {
    #[display(fmt = "Unknown")]
    Unknown              = 0,

    #[display(fmt = "Workspace name is invalid")]
    WorkspaceNameInvalid = 1,

    #[display(fmt = "Workspace id is invalid")]
    WorkspaceIdInvalid   = 2,

    #[display(fmt = "Color style of the App is invalid")]
    AppColorStyleInvalid = 3,

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

    #[display(fmt = "Get database connection failed")]
    DatabaseConnectionFail = 100,

    #[display(fmt = "Database internal error")]
    WorkspaceDatabaseError = 101,

    #[display(fmt = "User internal error")]
    UserInternalError    = 102,

    #[display(fmt = "User not login yet")]
    UserNotLoginYet      = 103,
}

impl std::default::Default for WsErrCode {
    fn default() -> Self { WsErrCode::Unknown }
}

impl std::convert::From<flowy_database::result::Error> for WorkspaceError {
    fn from(error: flowy_database::result::Error) -> Self {
        ErrorBuilder::new(WsErrCode::WorkspaceDatabaseError)
            .error(error)
            .build()
    }
}

impl flowy_dispatch::Error for WorkspaceError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

pub struct ErrorBuilder {
    pub code: WsErrCode,
    pub msg: Option<String>,
}

impl ErrorBuilder {
    pub fn new(code: WsErrCode) -> Self { ErrorBuilder { code, msg: None } }

    pub fn msg<T>(mut self, msg: T) -> Self
    where
        T: Into<String>,
    {
        self.msg = Some(msg.into());
        self
    }

    pub fn error<T>(mut self, msg: T) -> Self
    where
        T: std::fmt::Debug,
    {
        self.msg = Some(format!("{:?}", msg));
        self
    }

    pub fn build(mut self) -> WorkspaceError {
        WorkspaceError::new(self.code, &self.msg.take().unwrap_or("".to_owned()))
    }
}
