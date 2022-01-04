use bytes::Bytes;
use flowy_collaboration::entities::ws::DocumentClientWSData;
use flowy_database::ConnectionPool;
use flowy_document::{
    context::DocumentUser,
    core::{DocumentWSReceivers, DocumentWebSocket, WSStateReceiver},
    errors::{internal_error, FlowyError},
};
use flowy_net::services::ws::FlowyWSConnect;
use flowy_user::services::user::UserSession;
use lib_ws::{WSMessageReceiver, WSModule, WebSocketRawMessage};
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct DocumentDepsResolver();
impl DocumentDepsResolver {
    pub fn resolve(
        ws_manager: Arc<FlowyWSConnect>,
        user_session: Arc<UserSession>,
    ) -> (
        Arc<dyn DocumentUser>,
        Arc<DocumentWSReceivers>,
        Arc<dyn DocumentWebSocket>,
    ) {
        let user = Arc::new(DocumentUserImpl { user: user_session });

        let ws_sender = Arc::new(DocumentWebSocketAdapter {
            ws_manager: ws_manager.clone(),
        });
        let ws_receivers = Arc::new(DocumentWSReceivers::new());
        let receiver = Arc::new(WSMessageReceiverAdaptor(ws_receivers.clone()));
        ws_manager.add_receiver(receiver).unwrap();
        (user, ws_receivers, ws_sender)
    }
}

struct DocumentUserImpl {
    user: Arc<UserSession>,
}

impl DocumentUserImpl {}

impl DocumentUser for DocumentUserImpl {
    fn user_dir(&self) -> Result<String, FlowyError> {
        let dir = self
            .user
            .user_dir()
            .map_err(|e| FlowyError::unauthorized().context(e))?;

        let doc_dir = format!("{}/document", dir);
        if !Path::new(&doc_dir).exists() {
            let _ = std::fs::create_dir_all(&doc_dir)?;
        }
        Ok(doc_dir)
    }

    fn user_id(&self) -> Result<String, FlowyError> { self.user.user_id() }

    fn token(&self) -> Result<String, FlowyError> { self.user.token() }

    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> { self.user.db_pool() }
}

struct DocumentWebSocketAdapter {
    ws_manager: Arc<FlowyWSConnect>,
}

impl DocumentWebSocket for DocumentWebSocketAdapter {
    fn send(&self, data: DocumentClientWSData) -> Result<(), FlowyError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            module: WSModule::Doc,
            data: bytes.to_vec(),
        };
        let sender = self.ws_manager.ws_sender().map_err(internal_error)?;
        sender.send(msg).map_err(internal_error)?;

        Ok(())
    }

    fn subscribe_state_changed(&self) -> WSStateReceiver { self.ws_manager.subscribe_websocket_state() }
}

struct WSMessageReceiverAdaptor(Arc<DocumentWSReceivers>);

impl WSMessageReceiver for WSMessageReceiverAdaptor {
    fn source(&self) -> WSModule { WSModule::Doc }
    fn receive_message(&self, msg: WebSocketRawMessage) { self.0.did_receive_data(Bytes::from(msg.data)); }
}
