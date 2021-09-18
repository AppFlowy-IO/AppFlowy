use bytes::Bytes;
use flowy_derive::ProtoBuf;
use std::convert::{TryFrom, TryInto};
use tokio_tungstenite::tungstenite::Message;

#[derive(ProtoBuf, Debug, Clone, Default)]
pub struct WsMessage {
    #[pb(index = 1)]
    pub source: String,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

impl std::convert::Into<Message> for WsMessage {
    fn into(self) -> Message {
        let result: Result<Bytes, ::protobuf::ProtobufError> = self.try_into();
        match result {
            Ok(bytes) => Message::Binary(bytes.to_vec()),
            Err(e) => {
                log::error!("WsMessage serialize error: {:?}", e);
                Message::Binary(vec![])
            },
        }
    }
}

impl std::convert::From<Message> for WsMessage {
    fn from(value: Message) -> Self {
        match value {
            Message::Binary(bytes) => WsMessage::try_from(Bytes::from(bytes)).unwrap(),
            _ => {
                log::error!("WsMessage deserialize failed. Unsupported message");
                WsMessage::default()
            },
        }
    }
}
