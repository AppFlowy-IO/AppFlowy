use crate::service::ws::entities::SessionId;
use actix::Message;
use bytes::Bytes;
use std::fmt::Formatter;

#[derive(Debug, Clone)]
pub enum MessageData {
    Binary(Bytes),
    Connect(SessionId),
    Disconnect(SessionId),
}

#[derive(Debug, Message, Clone)]
#[rtype(result = "()")]
pub struct ClientMessage {
    pub session_id: SessionId,
    pub data: MessageData,
}

impl ClientMessage {
    pub fn new<T: Into<SessionId>>(session_id: T, data: MessageData) -> Self {
        ClientMessage {
            session_id: session_id.into(),
            data,
        }
    }
}

impl std::fmt::Display for ClientMessage {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let content = match &self.data {
            MessageData::Binary(_) => "[Binary]".to_owned(),
            MessageData::Connect(_) => "[Connect]".to_owned(),
            MessageData::Disconnect(_) => "[Disconnect]".to_owned(),
        };

        let desc = format!("{}:{}", &self.session_id, content);
        f.write_str(&desc)
    }
}
