use serde::{Deserialize, Serialize};
use serde_repr::*;
use tokio_tungstenite::tungstenite::Message as TokioMessage;

#[derive(Serialize, Deserialize, Debug, Clone, Default)]
pub struct WebSocketRawMessage {
    pub channel: WSChannel,
    pub data: Vec<u8>,
}

impl WebSocketRawMessage {
    pub fn to_bytes(&self) -> Vec<u8> {
        serde_json::to_vec(&self).unwrap_or_default()
    }

    pub fn from_bytes<T: AsRef<[u8]>>(bytes: T) -> Self {
        serde_json::from_slice(bytes.as_ref()).unwrap_or_default()
    }
}

// The lib-ws crate should not contain business logic.So WSChannel should be removed into another place.
#[derive(Serialize_repr, Deserialize_repr, Debug, Clone, Eq, PartialEq, Hash)]
#[repr(u8)]
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
        TokioMessage::Binary(msg.to_bytes())
    }
}
