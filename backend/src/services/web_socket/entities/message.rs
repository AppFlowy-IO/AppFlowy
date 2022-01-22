use actix::Message;
use bytes::Bytes;
use flowy_collaboration::entities::ws_data::ServerRevisionWSData;
use lib_ws::{WSChannel, WebSocketRawMessage};
use std::convert::TryInto;

#[derive(Debug, Message, Clone)]
#[rtype(result = "()")]
pub struct WebSocketMessage(pub Bytes);

impl std::ops::Deref for WebSocketMessage {
    type Target = Bytes;

    fn deref(&self) -> &Self::Target { &self.0 }
}

pub fn revision_data_to_ws_message(data: ServerRevisionWSData, channel: WSChannel) -> WebSocketMessage {
    let bytes: Bytes = data.try_into().unwrap();
    let msg = WebSocketRawMessage {
        channel,
        data: bytes.to_vec(),
    };
    let bytes: Bytes = msg.try_into().unwrap();
    WebSocketMessage(bytes)
}
