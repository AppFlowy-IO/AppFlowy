use actix::Message;
use bytes::Bytes;
use flowy_collaboration::entities::ws::DocumentWSData;
use lib_ws::{WSMessage, WSModule};
use std::convert::TryInto;

#[derive(Debug, Message, Clone)]
#[rtype(result = "()")]
pub struct WsMessageAdaptor(pub Bytes);

impl std::ops::Deref for WsMessageAdaptor {
    type Target = Bytes;

    fn deref(&self) -> &Self::Target { &self.0 }
}

impl std::convert::From<DocumentWSData> for WsMessageAdaptor {
    fn from(data: DocumentWSData) -> Self {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WSMessage {
            module: WSModule::Doc,
            data: bytes.to_vec(),
        };

        let bytes: Bytes = msg.try_into().unwrap();
        WsMessageAdaptor(bytes)
    }
}
