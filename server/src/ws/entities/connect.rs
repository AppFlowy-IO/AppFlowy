use crate::{errors::ServerError, ws::Packet};
use actix::{Message, Recipient};
use serde::{Deserialize, Serialize};
use std::fmt::Formatter;

#[derive(Serialize, Deserialize, Debug, Clone, Hash, PartialEq, Eq)]
pub struct SessionId {
    pub id: String,
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
    pub socket: Recipient<Packet>,
    pub sid: SessionId,
}

#[derive(Debug, Message, Clone)]
#[rtype(result = "Result<(), ServerError>")]
pub struct Disconnect {
    pub sid: SessionId,
}
