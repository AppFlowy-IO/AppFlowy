use crate::{entities::ws::WsDocumentData, errors::DocError};
use bytes::Bytes;
use lazy_static::lazy_static;
use std::{collections::HashMap, convert::TryInto, sync::Arc};

pub trait WsSender: Send + Sync {
    fn send_data(&self, data: Bytes) -> Result<(), DocError>;
}

pub struct WsManager {
    pub(crate) sender: Arc<dyn WsSender>,
    doc_handlers: HashMap<String, Arc<dyn WsHandler>>,
}

impl WsManager {
    pub fn new(sender: Arc<dyn WsSender>) -> Self {
        Self {
            sender,
            doc_handlers: HashMap::new(),
        }
    }

    pub(crate) fn register_handler(&mut self, id: &str, handler: Arc<dyn WsHandler>) {
        if self.doc_handlers.contains_key(id) {
            log::error!("Duplicate handler registered for {:?}", id);
        }

        self.doc_handlers.insert(id.to_string(), handler);
    }

    pub(crate) fn remove_handler(&mut self, id: &str) { self.doc_handlers.remove(id); }

    pub fn receive_data(&self, data: Bytes) {
        let data: WsDocumentData = data.try_into().unwrap();
        match self.doc_handlers.get(&data.id) {
            None => {
                log::error!("Can't find any source handler for {:?}", data.id);
            },
            Some(handler) => {
                handler.receive(data);
            },
        }
    }

    pub fn send_data(&self, data: WsDocumentData) {
        let bytes: Bytes = data.try_into().unwrap();
        match self.sender.send_data(bytes) {
            Ok(_) => {},
            Err(e) => {
                log::error!("WsDocument send message failed: {:?}", e);
            },
        }
    }
}

pub(crate) trait WsHandler: Send + Sync {
    fn receive(&self, data: WsDocumentData);
}
