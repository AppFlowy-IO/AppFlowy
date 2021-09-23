use crate::service::ws::ClientMessage;
use actix::{Message, Recipient};
use flowy_net::errors::ServerError;
use serde::{Deserialize, Serialize};
use std::fmt::Formatter;

pub type Socket = Recipient<ClientMessage>;

#[derive(Serialize, Deserialize, Debug, Clone, Hash, PartialEq, Eq)]
pub struct SessionId(pub String);

impl<T: AsRef<str>> std::convert::From<T> for SessionId {
    fn from(s: T) -> Self { SessionId(s.as_ref().to_owned()) }
}

impl std::fmt::Display for SessionId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let desc = format!("{}", &self.0);
        f.write_str(&desc)
    }
}

pub struct Session {
    pub id: SessionId,
    pub socket: Socket,
}

impl std::convert::From<Connect> for Session {
    fn from(c: Connect) -> Self {
        Self {
            id: c.sid,
            socket: c.socket,
        }
    }
}

#[derive(Debug, Message, Clone)]
#[rtype(result = "Result<(), ServerError>")]
pub struct Connect {
    pub socket: Socket,
    pub sid: SessionId,
}

#[derive(Debug, Message, Clone)]
#[rtype(result = "Result<(), ServerError>")]
pub struct Disconnect {
    pub sid: SessionId,
}
