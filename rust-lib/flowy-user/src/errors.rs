use derive_more::Display;
use flowy_dispatch::prelude::{DispatchError, EventResponse, ResponseBuilder, StatusCode};
use std::{io, sync::PoisonError};

#[derive(Debug, Clone, Display)]
pub enum UserError {
    #[display(fmt = "User db error:{}", _0)]
    Database(String),
    #[display(fmt = "User auth error:{}", _0)]
    Auth(String),
    #[display(fmt = "User sync error: {}", _0)]
    PoisonError(String),
}

impl std::convert::From<flowy_database::result::Error> for UserError {
    fn from(error: flowy_database::result::Error) -> Self {
        UserError::Database(format!("{:?}", error))
    }
}

impl std::convert::From<flowy_sqlite::Error> for UserError {
    fn from(e: flowy_sqlite::Error) -> Self { UserError::Database(format!("{:?}", e)) }
}

impl std::convert::From<UserError> for String {
    fn from(e: UserError) -> Self { format!("{:?}", e) }
}

impl std::convert::Into<DispatchError> for UserError {
    fn into(self) -> DispatchError {
        let user_error: String = self.into();
        user_error.into()
    }
}
