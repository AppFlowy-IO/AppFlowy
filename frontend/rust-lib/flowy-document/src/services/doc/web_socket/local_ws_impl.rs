use crate::services::doc::{web_socket::EditorWebSocket, DocumentWsHandler};
use flowy_collaboration::entities::ws::DocumentWSData;
use lib_ws::WSConnectState;
use std::sync::Arc;

pub(crate) struct EditorLocalWebSocket {}

impl EditorWebSocket for Arc<EditorLocalWebSocket> {
    fn stop_web_socket(&self) {}

    fn ws_handler(&self) -> Arc<dyn DocumentWsHandler> { self.clone() }
}

impl DocumentWsHandler for EditorLocalWebSocket {
    fn receive(&self, _doc_data: DocumentWSData) {}

    fn connect_state_changed(&self, _state: &WSConnectState) {}
}
