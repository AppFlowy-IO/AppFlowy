use crate::entities::token::{Claim, Token};

use chrono::{DateTime, Utc};
use dashmap::DashMap;
use flowy_net::errors::ServerError;

use actix_web::http::HeaderValue;
use lazy_static::lazy_static;

lazy_static! {
    pub static ref AUTHORIZED_USERS: AuthorizedUsers = AuthorizedUsers::new();
}

#[derive(Debug, PartialEq, Eq, Hash, Clone)]
pub struct LoggedUser {
    user_id: String,
}

impl std::convert::From<Claim> for LoggedUser {
    fn from(c: Claim) -> Self {
        Self {
            user_id: c.get_user_id(),
        }
    }
}

impl LoggedUser {
    pub fn new(user_id: &str) -> Self {
        Self {
            user_id: user_id.to_owned(),
        }
    }

    pub fn from_token(token: String) -> Result<Self, ServerError> {
        let user: LoggedUser = Token::decode_token(&token.into())?.into();
        Ok(user)
    }

    pub fn get_user_id(&self) -> Result<uuid::Uuid, ServerError> {
        let id = uuid::Uuid::parse_str(&self.user_id)?;
        Ok(id)
    }
}

use actix_web::{dev::Payload, FromRequest, HttpRequest};

use futures::future::{ready, Ready};

impl FromRequest for LoggedUser {
    type Config = ();
    type Error = ServerError;
    type Future = Ready<Result<Self, Self::Error>>;

    fn from_request(request: &HttpRequest, _payload: &mut Payload) -> Self::Future {
        match Token::parser_from_request(request) {
            Ok(token) => ready(LoggedUser::from_token(token.0)),
            Err(err) => ready(Err(err)),
        }
    }
}

impl std::convert::TryFrom<&HeaderValue> for LoggedUser {
    type Error = ServerError;

    fn try_from(header: &HeaderValue) -> Result<Self, Self::Error> {
        match header.to_str() {
            Ok(val) => LoggedUser::from_token(val.to_owned()),
            Err(e) => {
                log::error!("Header to string failed: {:?}", e);
                Err(ServerError::unauthorized())
            },
        }
    }
}

#[derive(Clone, Debug, Copy)]
enum AuthStatus {
    Authorized(DateTime<Utc>),
    NotAuthorized,
}

pub const EXPIRED_DURATION_DAYS: i64 = 5;

pub struct AuthorizedUsers(DashMap<LoggedUser, AuthStatus>);
impl AuthorizedUsers {
    pub fn new() -> Self { Self(DashMap::new()) }

    pub fn is_authorized(&self, user: &LoggedUser) -> bool {
        match self.0.get(user) {
            None => {
                log::debug!("user not login yet or server was reboot");
                false
            },
            Some(status) => match *status {
                AuthStatus::Authorized(last_time) => {
                    let current_time = Utc::now();
                    let days = (current_time - last_time).num_days();
                    log::debug!("user active {} from now", days);
                    days < EXPIRED_DURATION_DAYS
                },
                AuthStatus::NotAuthorized => {
                    log::debug!("user logout already");
                    false
                },
            },
        }
    }

    pub fn store_auth(&self, user: LoggedUser, is_auth: bool) -> Result<(), ServerError> {
        let status = if is_auth {
            AuthStatus::Authorized(Utc::now())
        } else {
            AuthStatus::NotAuthorized
        };
        self.0.insert(user, status);
        Ok(())
    }
}
