use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;
use tokio_tungstenite::tungstenite::Message as TokioMessage;

#[derive(ProtoBuf, Debug, Clone, Default)]
pub struct WebSocketRawMessage {
    #[pb(index = 1)]
    pub channel: WSChannel,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

// The lib-ws crate should not contain business logic.So WSChannel should be removed into another place.
#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Hash)]
pub enum WSChannel {
    Document = 0,
    Folder = 1,
    Grid = 2,
}

impl std::default::Default for WSChannel {
    fn default() -> Self {
        WSChannel::Document
    }
}

impl ToString for WSChannel {
    fn to_string(&self) -> String {
        match self {
            WSChannel::Document => "0".to_string(),
            WSChannel::Folder => "1".to_string(),
            WSChannel::Grid => "2".to_string(),
        }
    }
}

impl std::convert::From<WebSocketRawMessage> for TokioMessage {
    fn from(msg: WebSocketRawMessage) -> Self {
        let result: Result<Bytes, ::protobuf::ProtobufError> = msg.try_into();
        match result {
            Ok(bytes) => TokioMessage::Binary(bytes.to_vec()),
            Err(e) => {
                log::error!("WsMessage serialize error: {:?}", e);
                TokioMessage::Binary(vec![])
            }
        }
    }
}
