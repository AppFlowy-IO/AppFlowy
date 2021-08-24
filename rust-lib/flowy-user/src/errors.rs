use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use flowy_net::errors::Kind;
use std::{
    convert::TryInto,
    fmt::{Debug, Formatter},
};

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

#[derive(Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
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

    #[display(fmt = "Email can not be empty or whitespace")]
    EmailIsEmpty         = 20,
    #[display(fmt = "Email format is not valid")]
    EmailFormatInvalid   = 21,
    #[display(fmt = "Email already exists")]
    EmailAlreadyExists   = 22,
    #[display(fmt = "Password can not be empty or whitespace")]
    PasswordIsEmpty      = 30,
    #[display(fmt = "Password format too long")]
    PasswordTooLong      = 31,
    #[display(fmt = "Password contains forbidden characters.")]
    PasswordContainsForbidCharacters = 32,
    #[display(
        fmt = "Password should contain a minimum of 6 characters with 1 special 1 letter and 1 numeric"
    )]
    PasswordFormatInvalid = 33,

    #[display(fmt = "User name is too long")]
    UserNameTooLong      = 40,
    #[display(fmt = "User name contain forbidden characters")]
    UserNameContainsForbiddenCharacters = 41,
    #[display(fmt = "User name can not be empty or whitespace")]
    UserNameIsEmpty      = 42,
    #[display(fmt = "User workspace is invalid")]
    UserWorkspaceInvalid = 50,
    #[display(fmt = "User id is invalid")]
    UserIdInvalid        = 51,
    #[display(fmt = "Create user default workspace failed")]
    CreateDefaultWorkspaceFailed = 52,

    #[display(fmt = "User default workspace already exists")]
    DefaultWorkspaceAlreadyExist = 53,

    #[display(fmt = "Server error")]
    ServerError          = 100,
}

impl Debug for UserErrCode {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str(&format!("{}", self)) }
}

impl UserErrCode {
    pub fn to_string(&self) -> String { format!("{}", self) }
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

impl std::convert::From<flowy_net::errors::ServerError> for UserError {
    fn from(error: flowy_net::errors::ServerError) -> Self {
        ErrorBuilder::new(UserErrCode::ServerError)
            .error(error.msg)
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
    fn build(code: UserErrCode, msg: String) -> Self {
        let msg = if msg.is_empty() {
            format!("{}", code)
        } else {
            msg
        };
        UserError::new(code, &msg)
    }
}
