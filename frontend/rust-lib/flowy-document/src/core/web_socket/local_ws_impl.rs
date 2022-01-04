use crate::core::{web_socket::DocumentWebSocketManager, DocumentWSReceiver};
use flowy_collaboration::entities::ws::DocumentServerWSData;
use lib_ws::WSConnectState;
use std::sync::Arc;

pub(crate) struct LocalWebSocketManager {}

impl DocumentWebSocketManager for Arc<LocalWebSocketManager> {
    fn stop(&self) {}

    fn receiver(&self) -> Arc<dyn DocumentWSReceiver> { self.clone() }
}

impl DocumentWSReceiver for LocalWebSocketManager {
    fn receive_ws_data(&self, _doc_data: DocumentServerWSData) {}

    fn connect_state_changed(&self, _state: &WSConnectState) {}
}
