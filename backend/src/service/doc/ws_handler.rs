use crate::service::{util::parse_from_bytes, ws::WsBizHandler};
use bytes::Bytes;
use flowy_document::protobuf::Revision;
use protobuf::Message;

pub struct DocWsBizHandler {}

impl DocWsBizHandler {
    pub fn new() -> Self { Self {} }
}

impl WsBizHandler for DocWsBizHandler {
    fn receive_data(&self, data: Bytes) {
        let revision: Revision = parse_from_bytes(&data).unwrap();
        log::warn!("{:?}", revision);
    }
}
