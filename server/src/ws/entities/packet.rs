use crate::ws::entities::SessionId;
use actix::Message;
use bytes::Bytes;
use std::fmt::Formatter;

#[derive(Debug, Clone)]
pub enum Frame {
    Text(String),
    Binary(Bytes),
    Connect(SessionId),
    Disconnect(String),
}

#[derive(Debug, Message, Clone)]
#[rtype(result = "()")]
pub struct Packet {
    pub sid: SessionId,
    pub frame: Frame,
}

impl Packet {
    pub fn new(sid: SessionId, frame: Frame) -> Self { Packet { sid, frame } }
}

impl std::fmt::Display for Packet {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
        let content = match &self.frame {
            Frame::Text(t) => format!("[Text]: {}", t),
            Frame::Binary(_) => "[Binary message]".to_owned(),
            Frame::Connect(_) => "Connect".to_owned(),
            Frame::Disconnect(_) => "Disconnect".to_owned(),
        };

        let desc = format!("{}:{}", &self.sid, content);
        f.write_str(&desc)
    }
}
