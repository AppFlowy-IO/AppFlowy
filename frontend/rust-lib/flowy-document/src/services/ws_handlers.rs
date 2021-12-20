use crate::errors::FlowyError;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_collaboration::entities::ws::DocumentWSData;
use lib_ws::WSConnectState;
use std::{convert::TryInto, sync::Arc};

pub(crate) trait DocumentWsHandler: Send + Sync {
    fn receive(&self, data: DocumentWSData);
    fn connect_state_changed(&self, state: &WSConnectState);
}

pub type WsStateReceiver = tokio::sync::broadcast::Receiver<WSConnectState>;
pub trait DocumentWebSocket: Send + Sync {
    fn send(&self, data: DocumentWSData) -> Result<(), FlowyError>;
    fn subscribe_state_changed(&self) -> WsStateReceiver;
}

pub struct DocumentWsHandlers {
    ws: Arc<dyn DocumentWebSocket>,
    // key: the document id
    handlers: Arc<DashMap<String, Arc<dyn DocumentWsHandler>>>,
}

impl DocumentWsHandlers {
    pub fn new(ws: Arc<dyn DocumentWebSocket>) -> Self {
        let handlers: Arc<DashMap<String, Arc<dyn DocumentWsHandler>>> = Arc::new(DashMap::new());
        Self { ws, handlers }
    }

    pub(crate) fn init(&self) { listen_ws_state_changed(self.ws.clone(), self.handlers.clone()); }

    pub(crate) fn register_handler(&self, id: &str, handler: Arc<dyn DocumentWsHandler>) {
        if self.handlers.contains_key(id) {
            log::error!("Duplicate handler registered for {:?}", id);
        }
        self.handlers.insert(id.to_string(), handler);
    }

    pub(crate) fn remove_handler(&self, id: &str) { self.handlers.remove(id); }

    pub fn did_receive_data(&self, data: Bytes) {
        let data: DocumentWSData = data.try_into().unwrap();
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
fn listen_ws_state_changed(ws: Arc<dyn DocumentWebSocket>, handlers: Arc<DashMap<String, Arc<dyn DocumentWsHandler>>>) {
    let mut notify = ws.subscribe_state_changed();
    tokio::spawn(async move {
        while let Ok(state) = notify.recv().await {
            handlers.iter().for_each(|handle| {
                handle.value().connect_state_changed(&state);
            });
        }
    });
}
