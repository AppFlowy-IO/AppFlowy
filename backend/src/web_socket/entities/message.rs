use actix::Message;
use bytes::Bytes;
use flowy_collaboration::entities::ws::WsDocumentData;
use lib_ws::{WsMessage, WsModule};
use std::convert::TryInto;

#[derive(Debug, Message, Clone)]
#[rtype(result = "()")]
pub struct WsMessageAdaptor(pub Bytes);

impl std::ops::Deref for WsMessageAdaptor {
    type Target = Bytes;

    fn deref(&self) -> &Self::Target { &self.0 }
}

impl std::convert::From<WsDocumentData> for WsMessageAdaptor {
    fn from(data: WsDocumentData) -> Self {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WsMessage {
            module: WsModule::Doc,
            data: bytes.to_vec(),
        };

        let bytes: Bytes = msg.try_into().unwrap();
        WsMessageAdaptor(bytes)
    }
}
