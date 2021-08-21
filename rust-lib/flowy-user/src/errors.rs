use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::convert::TryInto;

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct UserError {
    #[pb(index = 1)]
    pub code: UserErrCode,

    #[pb(index = 2)]
    pub msg: String,
}

impl UserError {
    fn new(code: UserErrCode, msg: &str) -> Self {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum UserErrCode {
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

    #[display(fmt = "Network error")]
    NetworkError         = 100,
}

impl std::default::Default for UserErrCode {
    fn default() -> Self { UserErrCode::Unknown }
}

impl std::convert::From<flowy_database::result::Error> for UserError {
    fn from(error: flowy_database::result::Error) -> Self {
        ErrorBuilder::new(UserErrCode::UserDatabaseInternalError)
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

        ErrorBuilder::new(UserErrCode::SqlInternalError)
            .error(error)
            .build()
    }
}

impl std::convert::From<flowy_net::errors::NetworkError> for UserError {
    fn from(error: flowy_net::errors::NetworkError) -> Self {
        ErrorBuilder::new(UserErrCode::NetworkError)
            .error(error)
            .build()
    }
}

impl flowy_dispatch::Error for UserError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}

pub type ErrorBuilder = flowy_infra::errors::Builder<UserErrCode, UserError>;

impl flowy_infra::errors::Build<UserErrCode> for UserError {
    fn build(code: UserErrCode, msg: String) -> Self { UserError::new(code, &msg) }
}
