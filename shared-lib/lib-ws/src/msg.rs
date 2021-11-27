use bytes::Bytes;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use std::convert::TryInto;
use tokio_tungstenite::tungstenite::Message as TokioMessage;

// Opti: using four bytes of the data to represent the source
#[derive(ProtoBuf, Debug, Clone, Default)]
pub struct WsMessage {
    #[pb(index = 1)]
    pub module: WsModule,

    #[pb(index = 2)]
    pub data: Vec<u8>,
}

#[derive(ProtoBuf_Enum, Debug, Clone, Eq, PartialEq, Hash)]
pub enum WsModule {
    Doc = 0,
}

impl std::default::Default for WsModule {
    fn default() -> Self { WsModule::Doc }
}

impl ToString for WsModule {
    fn to_string(&self) -> String {
        match self {
            WsModule::Doc => "0".to_string(),
        }
    }
}

impl std::convert::From<WsMessage> for TokioMessage {
    fn from(msg: WsMessage) -> Self {
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
