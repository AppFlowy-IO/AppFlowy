use crate::{entities::ws::WsDocumentData, errors::DocError};
use bytes::Bytes;

use std::{collections::HashMap, convert::TryInto, sync::Arc};

pub(crate) trait WsDocumentHandler: Send + Sync {
    fn receive(&self, data: WsDocumentData);
}

pub trait WsDocumentSender: Send + Sync {
    fn send(&self, data: WsDocumentData) -> Result<(), DocError>;
}

pub struct WsDocumentManager {
    sender: Arc<dyn WsDocumentSender>,
    // key: the document id
    ws_handlers: HashMap<String, Arc<dyn WsDocumentHandler>>,
}

impl WsDocumentManager {
    pub fn new(sender: Arc<dyn WsDocumentSender>) -> Self {
        Self {
            sender,
            ws_handlers: HashMap::new(),
        }
    }

    pub(crate) fn register_handler(&mut self, id: &str, handler: Arc<dyn WsDocumentHandler>) {
        if self.ws_handlers.contains_key(id) {
            log::error!("Duplicate handler registered for {:?}", id);
        }

        self.ws_handlers.insert(id.to_string(), handler);
    }

    pub(crate) fn remove_handler(&mut self, id: &str) { self.ws_handlers.remove(id); }

    pub fn receive_data(&self, data: Bytes) {
        let data: WsDocumentData = data.try_into().unwrap();
        match self.ws_handlers.get(&data.id) {
            None => {
                log::error!("Can't find any source handler for {:?}", data.id);
            },
            Some(handler) => {
                handler.receive(data);
            },
        }
    }

    pub fn sender(&self) -> Arc<dyn WsDocumentSender> { self.sender.clone() }
}
