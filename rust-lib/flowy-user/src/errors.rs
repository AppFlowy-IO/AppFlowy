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
    UserDatabaseInitFailed = 1,
    #[display(fmt = "Get database write lock failed")]
    UserDatabaseWriteLocked = 2,
    #[display(fmt = "Get database read lock failed")]
    UserDatabaseReadLocked = 3,
    #[display(fmt = "Opening database is not belonging to the current user")]
    UserDatabaseDidNotMatch = 4,
    #[display(fmt = "Database internal error")]
    UserDatabaseInternalError = 5,

    #[display(fmt = "Sql internal error")]
    SqlInternalError     = 6,

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
    #[display(fmt = "User name is invalid")]
    UserNameInvalid      = 22,
    #[display(fmt = "User workspace is invalid")]
    UserWorkspaceInvalid = 23,
    #[display(fmt = "User id is invalid")]
    UserIdInvalid        = 24,
    #[display(fmt = "Create user default workspace failed")]
    CreateDefaultWorkspaceFailed = 25,

    #[display(fmt = "User default workspace already exists")]
    DefaultWorkspaceAlreadyExist = 26,
}

impl std::default::Default for UserErrorCode {
    fn default() -> Self { UserErrorCode::Unknown }
}

impl std::convert::From<flowy_database::result::Error> for UserError {
    fn from(error: flowy_database::result::Error) -> Self {
        ErrorBuilder::new(UserErrorCode::UserDatabaseInternalError)
            .error(error)
            .build()
    }
}
// use diesel::result::{Error, DatabaseErrorKind};
// use flowy_sqlite::ErrorKind;
impl std::convert::From<flowy_sqlite::Error> for UserError {
    fn from(error: flowy_sqlite::Error) -> Self {
        // match error.kind() {
        //     ErrorKind::Msg(_) => {},
        //     ErrorKind::R2D2(_) => {},
        //     ErrorKind::Migrations(_) => {},
        //     ErrorKind::Diesel(diesel_err) => match diesel_err {
        //         Error::InvalidCString(_) => {},
        //         Error::DatabaseError(kind, _) => {
        //             match kind {
        //                 DatabaseErrorKind::UniqueViolation => {
        //
        //                 }
        //                 _ => {}
        //             }
        //         },
        //         Error::NotFound => {},
        //         Error::QueryBuilderError(_) => {},
        //         Error::DeserializationError(_) => {},
        //         Error::SerializationError(_) => {},
        //         Error::RollbackTransaction => {},
        //         Error::AlreadyInTransaction => {},
        //         Error::__Nonexhaustive => {},
        //     },
        //     ErrorKind::Connection(_) => {},
        //     ErrorKind::Io(_) => {},
        //     ErrorKind::UnknownMigrationExists(_) => {},
        //     ErrorKind::__Nonexhaustive { .. } => {},
        // }

        ErrorBuilder::new(UserErrorCode::SqlInternalError)
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
