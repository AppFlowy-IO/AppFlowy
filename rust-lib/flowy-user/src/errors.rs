use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::convert::TryInto;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct UserError {
    #[pb(index = 1)]
    pub code: UserErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

impl UserError {
    fn new(code: UserErrorCode, msg: &str) -> Self {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum UserErrorCode {
    #[display(fmt = "Unknown")]
    Unknown              = 0,
    #[display(fmt = "Database init failed")]
    DatabaseInitFailed   = 1,
    #[display(fmt = "Get database write lock failed")]
    DatabaseWriteLocked  = 2,
    #[display(fmt = "Get database read lock failed")]
    DatabaseReadLocked   = 3,
    #[display(fmt = "Opening database is not belonging to the current user")]
    DatabaseUserDidNotMatch = 4,
    #[display(fmt = "Database internal error")]
    DatabaseInternalError = 5,

    #[display(fmt = "User not login yet")]
    UserNotLoginYet      = 10,
    #[display(fmt = "Get current id read lock failed")]
    ReadCurrentIdFailed  = 11,
    #[display(fmt = "Get current id write lock failed")]
    WriteCurrentIdFailed = 12,

    #[display(fmt = "Email format is not correct")]
    EmailInvalid         = 20,
    #[display(fmt = "Password format is not correct")]
    PasswordInvalid      = 21,
    #[display(fmt = "User is invalid")]
    UserNameInvalid      = 22,
}

impl std::default::Default for UserErrorCode {
    fn default() -> Self { UserErrorCode::Unknown }
}

impl std::convert::From<flowy_database::result::Error> for UserError {
    fn from(error: flowy_database::result::Error) -> Self {
        ErrorBuilder::new(UserErrorCode::DatabaseInternalError)
            .error(error)
            .build()
    }
}

impl std::convert::From<flowy_sqlite::Error> for UserError {
    fn from(error: flowy_sqlite::Error) -> Self {
        ErrorBuilder::new(UserErrorCode::DatabaseInternalError)
            .error(error)
            .build()
    }
}

impl flowy_dispatch::Error for UserError {
    fn as_response(&self) -> EventResponse {
        let bytes: Vec<u8> = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

pub struct ErrorBuilder {
    pub code: UserErrorCode,
    pub msg: Option<String>,
}

impl ErrorBuilder {
    pub fn new(code: UserErrorCode) -> Self { ErrorBuilder { code, msg: None } }

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

    pub fn build(mut self) -> UserError {
        UserError::new(self.code, &self.msg.take().unwrap_or("".to_owned()))
    }
}
