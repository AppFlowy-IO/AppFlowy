use crate::errors::FlowyError;
use async_trait::async_trait;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::{DocumentClientWSData, DocumentServerWSData};
use lib_ws::WSConnectState;
use std::{convert::TryInto, sync::Arc};

#[async_trait]
pub(crate) trait DocumentWSReceiver: Send + Sync {
    async fn receive_ws_data(&self, data: DocumentServerWSData) -> Result<(), FlowyError>;
    fn connect_state_changed(&self, state: WSConnectState);
}

pub type WSStateReceiver = tokio::sync::broadcast::Receiver<WSConnectState>;
pub trait DocumentWebSocket: Send + Sync {
    fn send(&self, data: DocumentClientWSData) -> Result<(), FlowyError>;
    fn subscribe_state_changed(&self) -> WSStateReceiver;
}

pub struct DocumentWSReceivers {
    // key: the document id
    // value: DocumentWSReceiver
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

    pub(crate) fn add(&self, doc_id: &str, receiver: Arc<dyn DocumentWSReceiver>) {
        if self.receivers.contains_key(doc_id) {
            log::error!("Duplicate handler registered for {:?}", doc_id);
        }
        self.receivers.insert(doc_id.to_string(), receiver);
    }

    pub(crate) fn remove(&self, id: &str) { self.receivers.remove(id); }

    pub async fn did_receive_data(&self, data: Bytes) {
        let data: DocumentServerWSData = data.try_into().unwrap();
        match self.receivers.get(&data.doc_id) {
            None => tracing::error!("Can't find any source handler for {:?}", data.doc_id),
            Some(handler) => match handler.receive_ws_data(data).await {
                Ok(_) => {},
                Err(e) => tracing::error!("{}", e),
            },
        }
    }

    pub async fn ws_connect_state_changed(&self, state: &WSConnectState) {
        for receiver in self.receivers.iter() {
            receiver.value().connect_state_changed(state.clone());
        }
    }
}
