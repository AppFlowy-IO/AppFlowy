use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::{TryFrom, TryInto};
use tokio_tungstenite::tungstenite::Message as TokioMessage;

#[derive(ProtoBuf, Debug, Clone, Default)]
pub struct WsMessage {
    #[pb(index = 1)]
    pub source: WsSource,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Hash)]
pub enum WsSource {
    Doc = 0,
}

impl std::default::Default for WsSource {
    fn default() -> Self { WsSource::Doc }
}

impl ToString for WsSource {
    fn to_string(&self) -> String {
        match self {
            WsSource::Doc => "0".to_string(),
        }
    }
}

impl std::convert::Into<TokioMessage> for WsMessage {
    fn into(self) -> TokioMessage {
        let result: Result<Bytes, ::protobuf::ProtobufError> = self.try_into();
        match result {
            Ok(bytes) => TokioMessage::Binary(bytes.to_vec()),
            Err(e) => {
                log::error!("WsMessage serialize error: {:?}", e);
                TokioMessage::Binary(vec![])
            },
        }
    }
}

impl std::convert::From<TokioMessage> for WsMessage {
    fn from(value: TokioMessage) -> Self {
        match value {
            TokioMessage::Binary(bytes) => WsMessage::try_from(Bytes::from(bytes)).unwrap(),
            _ => {
                log::error!("WsMessage deserialize failed. Unsupported message");
                WsMessage::default()
            },
        }
    }
}
