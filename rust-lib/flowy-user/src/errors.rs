use bytes::Bytes;
use derive_more::Display;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::{convert::TryInto, fmt, fmt::Debug};

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct UserError {
    #[pb(index = 1)]
    pub code: ErrorCode,

    #[pb(index = 2)]
    pub msg: String,
}

impl std::fmt::Display for UserError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}: {}", &self.code, &self.msg) }
}

macro_rules! static_user_error {
    ($name:ident, $status:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> UserError {
            UserError {
                code: $status,
                msg: format!("{}", $status),
            }
        }
    };
}

impl UserError {
    pub(crate) fn new(code: ErrorCode, msg: &str) -> Self {
        Self {
            code,
            msg: msg.to_owned(),
        }
    }

    pub(crate) fn code(code: ErrorCode) -> Self {
        Self {
            msg: format!("{}", &code),
            code,
        }
    }

    pub fn context<T: Debug>(mut self, error: T) -> Self {
        self.msg = format!("{:?}", error);
        self
    }

    static_user_error!(email_empty, ErrorCode::EmailIsEmpty);
    static_user_error!(email_format, ErrorCode::EmailFormatInvalid);
    static_user_error!(email_exist, ErrorCode::EmailAlreadyExists);
    static_user_error!(password_empty, ErrorCode::PasswordIsEmpty);
    static_user_error!(passworkd_too_long, ErrorCode::PasswordTooLong);
    static_user_error!(password_forbid_char, ErrorCode::PasswordContainsForbidCharacters);
    static_user_error!(password_format, ErrorCode::PasswordFormatInvalid);
    static_user_error!(password_not_match, ErrorCode::PasswordNotMatch);
    static_user_error!(name_too_long, ErrorCode::UserNameTooLong);
    static_user_error!(name_forbid_char, ErrorCode::UserNameContainForbiddenCharacters);
    static_user_error!(name_empty, ErrorCode::UserNameIsEmpty);
    static_user_error!(user_id, ErrorCode::UserIdInvalid);
    static_user_error!(unauthorized, ErrorCode::UserUnauthorized);
    static_user_error!(user_not_exist, ErrorCode::UserNotExist);
    static_user_error!(internal, ErrorCode::InternalError);
}

#[derive(Debug, Clone, ProtoBuf_Enum, Display, PartialEq, Eq)]
pub enum ErrorCode {
    #[display(fmt = "Email can not be empty or whitespace")]
    EmailIsEmpty       = 0,
    #[display(fmt = "Email format is not valid")]
    EmailFormatInvalid = 1,
    #[display(fmt = "Email already exists")]
    EmailAlreadyExists = 2,
    #[display(fmt = "Password can not be empty or whitespace")]
    PasswordIsEmpty    = 10,
    #[display(fmt = "Password format too long")]
    PasswordTooLong    = 11,
    #[display(fmt = "Password contains forbidden characters.")]
    PasswordContainsForbidCharacters = 12,
    #[display(fmt = "Password should contain a minimum of 6 characters with 1 special 1 letter and 1 numeric")]
    PasswordFormatInvalid = 13,
    #[display(fmt = "Password not match")]
    PasswordNotMatch   = 14,
    #[display(fmt = "User name is too long")]
    UserNameTooLong    = 20,
    #[display(fmt = "User name contain forbidden characters")]
    UserNameContainForbiddenCharacters = 21,
    #[display(fmt = "User name can not be empty or whitespace")]
    UserNameIsEmpty    = 22,
    #[display(fmt = "User id is invalid")]
    UserIdInvalid      = 23,
    #[display(fmt = "User token is invalid")]
    UserUnauthorized   = 24,
    #[display(fmt = "User not exist")]
    UserNotExist       = 25,

    #[display(fmt = "Server is offline, try again later")]
    ServerOffline       = 26,

    #[display(fmt = "Internal error")]
    InternalError      = 100,
}

impl std::convert::Into<UserError> for ErrorCode {
    fn into(self) -> UserError { UserError::new(self, "") }
}

impl std::default::Default for ErrorCode {
    fn default() -> Self { ErrorCode::InternalError }
}

impl std::convert::From<flowy_database::Error> for UserError {
    fn from(error: flowy_database::Error) -> Self {
        match error {
            flowy_database::Error::NotFound => UserError::user_not_exist().context(error),
            _ => UserError::internal().context(error),
        }
    }
}

impl std::convert::From<::r2d2::Error> for UserError {
    fn from(error: r2d2::Error) -> Self { UserError::internal().context(error) }
}

impl std::convert::From<flowy_ws::errors::WsError> for UserError {
    fn from(error: flowy_ws::errors::WsError) -> Self {
        match error.code {
            flowy_ws::errors::ErrorCode::InternalError => UserError::internal().context(error.msg),
            _ => UserError::internal().context(error),
        }
    }
}

// use diesel::result::{Error, DatabaseErrorKind};
// use flowy_sqlite::ErrorKind;
impl std::convert::From<flowy_sqlite::Error> for UserError {
    fn from(error: flowy_sqlite::Error) -> Self { UserError::internal().context(error) }
}

impl std::convert::From<flowy_net::errors::ServerError> for UserError {
    fn from(error: flowy_net::errors::ServerError) -> Self {
        let (code, msg) = server_error_to_user_error(error);
        UserError::new(code, &msg)
    }
}

use flowy_net::errors::ErrorCode as ServerErrorCode;
fn server_error_to_user_error(error: flowy_net::errors::ServerError) -> (ErrorCode, String) {
    let code = match error.code {
        ServerErrorCode::UserUnauthorized => ErrorCode::UserUnauthorized,
        ServerErrorCode::PasswordNotMatch => ErrorCode::PasswordNotMatch,
        ServerErrorCode::RecordNotFound => ErrorCode::UserNotExist,
        ServerErrorCode::ConnectRefused | ServerErrorCode::ConnectTimeout | ServerErrorCode::ConnectClose => ErrorCode::ServerOffline,
        _ => ErrorCode::InternalError,
    };

    if code != ErrorCode::InternalError {
        let msg = format!("{}", &code);
        (code, msg)
    } else {
        (code, error.msg)
    }
}

impl flowy_dispatch::Error for UserError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}
