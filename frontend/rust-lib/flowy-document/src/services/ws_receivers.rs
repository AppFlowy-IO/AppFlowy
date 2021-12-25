use crate::errors::FlowyError;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::DocumentWSData;
use lib_ws::WSConnectState;
use std::{convert::TryInto, sync::Arc};

pub(crate) trait DocumentWSReceiver: Send + Sync {
    fn receive_ws_data(&self, data: DocumentWSData);
    fn connect_state_changed(&self, state: &WSConnectState);
}

pub type WSStateReceiver = tokio::sync::broadcast::Receiver<WSConnectState>;
pub trait DocumentWebSocket: Send + Sync {
    fn send(&self, data: DocumentWSData) -> Result<(), FlowyError>;
    fn subscribe_state_changed(&self) -> WSStateReceiver;
}

pub struct DocumentWSReceivers {
    // key: the document id
    receivers: Arc<DashMap<String, Arc<dyn DocumentWSReceiver>>>,
}

impl std::default::Default for DocumentWSReceivers {
    fn default() -> Self {
        let receivers: Arc<DashMap<String, Arc<dyn DocumentWSReceiver>>> = Arc::new(DashMap::new());
        DocumentWSReceivers { receivers }
    }
}

impl DocumentWSReceivers {
    pub fn new() -> Self { DocumentWSReceivers::default() }

    pub(crate) fn register_receiver(&self, doc_id: &str, receiver: Arc<dyn DocumentWSReceiver>) {
        if self.receivers.contains_key(doc_id) {
            log::error!("Duplicate handler registered for {:?}", doc_id);
        }
        self.receivers.insert(doc_id.to_string(), receiver);
    }

    pub(crate) fn remove_receiver(&self, id: &str) { self.receivers.remove(id); }

    pub fn did_receive_data(&self, data: Bytes) {
        let data: DocumentWSData = data.try_into().unwrap();
        match self.receivers.get(&data.doc_id) {
            None => {
                log::error!("Can't find any source handler for {:?}", data.doc_id);
            },
            Some(handler) => {
                handler.receive_ws_data(data);
            },
        }
    }

    pub fn ws_connect_state_changed(&self, state: &WSConnectState) {
        self.receivers.iter().for_each(|receiver| {
            receiver.value().connect_state_changed(&state);
        });
    }
}
