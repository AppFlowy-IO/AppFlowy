use bytes::Bytes;

use flowy_derive::ProtoBuf;
pub use flowy_user_infra::errors::ErrorCode;
use lib_dispatch::prelude::{EventResponse, ResponseBuilder};
use std::{convert::TryInto, fmt, fmt::Debug};

#[derive(Debug, Default, Clone, ProtoBuf)]
pub struct UserError {
    #[pb(index = 1)]
    pub code: i32,

    #[pb(index = 2)]
    pub msg: String,
}

impl std::fmt::Display for UserError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { write!(f, "{:?}: {}", &self.code, &self.msg) }
}

macro_rules! static_user_error {
    ($name:ident, $code:expr) => {
        #[allow(non_snake_case, missing_docs)]
        pub fn $name() -> UserError { $code.into() }
    };
}

impl UserError {
    pub(crate) fn new(code: ErrorCode, msg: &str) -> Self {
        Self {
            code: code.value(),
            msg: msg.to_owned(),
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

impl std::convert::From<ErrorCode> for UserError {
    fn from(code: ErrorCode) -> Self {
        UserError {
            code: code.value(),
            msg: format!("{}", code),
        }
    }
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

impl std::convert::From<lib_ws::errors::WsError> for UserError {
    fn from(error: lib_ws::errors::WsError) -> Self {
        match error.code {
            lib_ws::errors::ErrorCode::InternalError => UserError::internal().context(error.msg),
            _ => UserError::internal().context(error),
        }
    }
}

// use diesel::result::{Error, DatabaseErrorKind};
// use lib_sqlite::ErrorKind;
impl std::convert::From<lib_sqlite::Error> for UserError {
    fn from(error: lib_sqlite::Error) -> Self { UserError::internal().context(error) }
}

impl std::convert::From<backend_service::errors::ServerError> for UserError {
    fn from(error: backend_service::errors::ServerError) -> Self {
        let (code, msg) = server_error_to_user_error(error);
        UserError::new(code, &msg)
    }
}

use backend_service::errors::ErrorCode as ServerErrorCode;
fn server_error_to_user_error(error: backend_service::errors::ServerError) -> (ErrorCode, String) {
    let code = match error.code {
        ServerErrorCode::UserUnauthorized => ErrorCode::UserUnauthorized,
        ServerErrorCode::PasswordNotMatch => ErrorCode::PasswordNotMatch,
        ServerErrorCode::RecordNotFound => ErrorCode::UserNotExist,
        ServerErrorCode::ConnectRefused | ServerErrorCode::ConnectTimeout | ServerErrorCode::ConnectClose => {
            ErrorCode::ServerError
        },
        _ => ErrorCode::InternalError,
    };

    if code != ErrorCode::InternalError {
        let msg = format!("{}", &code);
        (code, msg)
    } else {
        (code, error.msg)
    }
}

impl lib_dispatch::Error for UserError {
    fn as_response(&self) -> EventResponse {
        let bytes: Bytes = self.clone().try_into().unwrap();
        ResponseBuilder::Err().data(bytes).build()
    }
}
