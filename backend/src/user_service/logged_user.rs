use crate::entities::token::{Claim, Token};

use chrono::{DateTime, Utc};
use dashmap::DashMap;
use flowy_net::errors::ServerError;

use lazy_static::lazy_static;

lazy_static! {
    pub static ref AUTHORIZED_USERS: AuthorizedUsers = AuthorizedUsers::new();
}

#[derive(Debug, PartialEq, Eq, Hash, Clone)]
pub struct LoggedUser {
    pub email: String,
}

impl std::convert::From<Claim> for LoggedUser {
    fn from(c: Claim) -> Self {
        Self {
            email: c.get_email(),
        }
    }
}

impl std::convert::From<String> for LoggedUser {
    fn from(email: String) -> Self { Self { email } }
}

impl LoggedUser {
    pub fn from_token(token: String) -> Result<Self, ServerError> {
        let user: LoggedUser = Token::decode_token(&token.into())?.into();
        match AUTHORIZED_USERS.is_authorized(&user) {
            true => Ok(user),
            false => Err(ServerError::unauthorized()),
        }
    }
}

// use futures::{
//     executor::block_on,
//     future::{ready, Ready},
// };
// impl FromRequest for LoggedUser {
//     type Config = ();
//     type Error = ServerError;
//     type Future = Ready<Result<Self, Self::Error>>;
//
//     fn from_request(_req: &HttpRequest, payload: &mut Payload) ->
// Self::Future {         let result: Result<SignOutParams, ServerError> =
// block_on(parse_from_dev_payload(payload));         match result {
//             Ok(params) => ready(LoggedUser::from_token(params.token)),
//             Err(e) => ready(Err(e)),
//         }
//     }
// }

#[derive(Clone, Debug, Copy)]
enum AuthStatus {
    Authorized(DateTime<Utc>),
    NotAuthorized,
}

pub struct AuthorizedUsers(DashMap<LoggedUser, AuthStatus>);
impl AuthorizedUsers {
    pub fn new() -> Self { Self(DashMap::new()) }

    pub fn is_authorized(&self, user: &LoggedUser) -> bool {
        match self.0.get(user) {
            None => false,
            Some(status) => match *status {
                AuthStatus::Authorized(last_time) => {
                    let current_time = Utc::now();
                    (current_time - last_time).num_days() < 5
                },
                AuthStatus::NotAuthorized => false,
            },
        }
    }

    pub fn store_auth(&self, user: LoggedUser, is_auth: bool) -> Result<(), ServerError> {
        let current_time = Utc::now();
        let status = if is_auth {
            AuthStatus::Authorized(current_time)
        } else {
            AuthStatus::NotAuthorized
        };
        self.0.insert(user, status);
        Ok(())
    }
}
