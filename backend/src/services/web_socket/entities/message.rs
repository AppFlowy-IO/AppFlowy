use actix::Message;
use bytes::Bytes;
use flowy_collaboration::entities::ws::{ClientRevisionWSData, ServerRevisionWSData};
use lib_ws::{WSModule, WebSocketRawMessage};
use std::convert::TryInto;

#[derive(Debug, Message, Clone)]
#[rtype(result = "()")]
pub struct WebSocketMessage(pub Bytes);

impl std::ops::Deref for WebSocketMessage {
    type Target = Bytes;

    fn deref(&self) -> &Self::Target { &self.0 }
}

impl std::convert::From<ClientRevisionWSData> for WebSocketMessage {
    fn from(data: ClientRevisionWSData) -> Self {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            module: WSModule::Doc,
            data: bytes.to_vec(),
        };

        let bytes: Bytes = msg.try_into().unwrap();
        WebSocketMessage(bytes)
    }
}

impl std::convert::From<ServerRevisionWSData> for WebSocketMessage {
    fn from(data: ServerRevisionWSData) -> Self {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            module: WSModule::Doc,
            data: bytes.to_vec(),
        };
        let bytes: Bytes = msg.try_into().unwrap();
        WebSocketMessage(bytes)
    }
}
