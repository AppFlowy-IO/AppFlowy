use crate::errors::DocError;
use bytes::Bytes;
use lazy_static::lazy_static;
use std::{convert::TryFrom, sync::Arc};

pub struct WsDocumentMessage(pub Bytes);

pub trait WsSender: Send + Sync {
    fn send_msg(&self, msg: WsDocumentMessage) -> Result<(), DocError>;
}

lazy_static! {
    pub static ref WS_ID: String = "Document".to_string();
}

pub struct WsDocument {
    sender: Arc<dyn WsSender>,
}
impl WsDocument {
    pub fn new(sender: Arc<dyn WsSender>) -> Self { Self { sender } }
    pub fn receive_msg(&self, _msg: WsDocumentMessage) { unimplemented!() }
    pub fn send_msg(&self, _msg: WsDocumentMessage) { unimplemented!() }
}

pub enum WsSource {
    Delta,
}

impl AsRef<str> for WsSource {
    fn as_ref(&self) -> &str {
        match self {
            WsSource::Delta => "delta",
        }
    }
}

impl ToString for WsSource {
    fn to_string(&self) -> String {
        match self {
            WsSource::Delta => self.as_ref().to_string(),
        }
    }
}

impl TryFrom<String> for WsSource {
    type Error = DocError;
    fn try_from(value: String) -> Result<Self, Self::Error> {
        match value.as_str() {
            "delta" => Ok(WsSource::Delta),
            _ => Err(DocError::internal().context(format!("Deserialize WsSource failed. Unknown type: {}", &value))),
        }
    }
}
