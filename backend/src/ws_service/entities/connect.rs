use crate::ws_service::ClientMessage;
use actix::{Message, Recipient};
use flowy_net::response::ServerError;
use serde::{Deserialize, Serialize};
use std::fmt::Formatter;

pub type Socket = Recipient<ClientMessage>;

#[derive(Serialize, Deserialize, Debug, Clone, Hash, PartialEq, Eq)]
pub struct SessionId {
    pub id: String,
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

impl SessionId {
    pub fn new(id: String) -> Self { SessionId { id } }
}

impl std::fmt::Display for SessionId {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let desc = format!("{}", &self.id);
        f.write_str(&desc)
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
