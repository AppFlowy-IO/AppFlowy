use crate::errors::DocError;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_document_infra::entities::ws::WsDocumentData;
use lib_ws::WsConnectState;
use std::{convert::TryInto, sync::Arc};

pub(crate) trait WsDocumentHandler: Send + Sync {
    fn receive(&self, data: WsDocumentData);
    fn state_changed(&self, state: &WsConnectState);
}

pub type WsStateReceiver = tokio::sync::broadcast::Receiver<WsConnectState>;
pub trait DocumentWebSocket: Send + Sync {
    fn send(&self, data: WsDocumentData) -> Result<(), DocError>;
    fn state_notify(&self) -> WsStateReceiver;
}

pub struct WsDocumentManager {
    ws: Arc<dyn DocumentWebSocket>,
    // key: the document id
    handlers: Arc<DashMap<String, Arc<dyn WsDocumentHandler>>>,
}

impl WsDocumentManager {
    pub fn new(ws: Arc<dyn DocumentWebSocket>) -> Self {
        let handlers: Arc<DashMap<String, Arc<dyn WsDocumentHandler>>> = Arc::new(DashMap::new());
        Self { ws, handlers }
    }

    pub(crate) fn init(&self) { listen_ws_state_changed(self.ws.clone(), self.handlers.clone()); }

    pub(crate) fn register_handler(&self, id: &str, handler: Arc<dyn WsDocumentHandler>) {
        if self.handlers.contains_key(id) {
            log::error!("Duplicate handler registered for {:?}", id);
        }
        self.handlers.insert(id.to_string(), handler);
    }

    pub(crate) fn remove_handler(&self, id: &str) { self.handlers.remove(id); }

    pub fn did_receive_ws_data(&self, data: Bytes) {
        let data: WsDocumentData = data.try_into().unwrap();
        match self.handlers.get(&data.doc_id) {
            None => {
                log::error!("Can't find any source handler for {:?}", data.doc_id);
            },
            Some(handler) => {
                handler.receive(data);
            },
        }
    }

    pub fn ws(&self) -> Arc<dyn DocumentWebSocket> { self.ws.clone() }
}

#[tracing::instrument(level = "debug", skip(ws, handlers))]
fn listen_ws_state_changed(ws: Arc<dyn DocumentWebSocket>, handlers: Arc<DashMap<String, Arc<dyn WsDocumentHandler>>>) {
    let mut notify = ws.state_notify();
    tokio::spawn(async move {
        while let Ok(state) = notify.recv().await {
            handlers.iter().for_each(|handle| {
                handle.value().state_changed(&state);
            });
        }
    });
}
