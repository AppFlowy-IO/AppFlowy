use crate::service::ws_service::entities::SessionId;
use actix::Message;
use bytes::Bytes;
use std::fmt::Formatter;

#[derive(Debug, Clone)]
pub enum MessageData {
    Text(String),
    Binary(Bytes),
    Connect(SessionId),
    Disconnect(String),
}

#[derive(Debug, Message, Clone)]
#[rtype(result = "()")]
pub struct ClientMessage {
    pub sid: SessionId,
    pub data: MessageData,
}

impl ClientMessage {
    pub fn new(sid: SessionId, data: MessageData) -> Self { ClientMessage { sid, data } }
}

impl std::fmt::Display for ClientMessage {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let content = match &self.data {
            MessageData::Text(t) => format!("[Text]: {}", t),
            MessageData::Binary(_) => "[Binary message]".to_owned(),
            MessageData::Connect(_) => "Connect".to_owned(),
            MessageData::Disconnect(_) => "Disconnect".to_owned(),
        };

        let desc = format!("{}:{}", &self.sid, content);
        f.write_str(&desc)
    }
}
