use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;
use tokio_tungstenite::tungstenite::Message as TokioMessage;

#[derive(ProtoBuf, Debug, Clone, Default)]
pub struct WebScoketRawMessage {
    #[pb(index = 1)]
    pub module: WSModule,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Hash)]
pub enum WSModule {
    Doc = 0,
}

impl std::default::Default for WSModule {
    fn default() -> Self { WSModule::Doc }
}

impl ToString for WSModule {
    fn to_string(&self) -> String {
        match self {
            WSModule::Doc => "0".to_string(),
        }
    }
}

impl std::convert::From<WebScoketRawMessage> for TokioMessage {
    fn from(msg: WebScoketRawMessage) -> Self {
        let result: Result<Bytes, ::protobuf::ProtobufError> = msg.try_into();
        match result {
            Ok(bytes) => TokioMessage::Binary(bytes.to_vec()),
            Err(e) => {
                log::error!("WsMessage serialize error: {:?}", e);
                TokioMessage::Binary(vec![])
            },
        }
    }
}
