use bytes::Bytes;
use flowy_collaboration::entities::ws::WsDocumentData;
use flowy_database::ConnectionPool;
use flowy_document::{
    errors::{internal_error, FlowyError},
    module::DocumentUser,
    services::doc::{DocumentWebSocket, DocumentWsHandlers, WsStateReceiver},
};
use flowy_net::services::ws::WsManager;
use flowy_user::services::user::UserSession;
use lib_ws::{WsMessage, WsMessageReceiver, WsModule};
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct DocumentDepsResolver();
impl DocumentDepsResolver {
    pub fn resolve(
        ws_manager: Arc<WsManager>,
        user_session: Arc<UserSession>,
    ) -> (Arc<dyn DocumentUser>, Arc<DocumentWsHandlers>) {
        let user = Arc::new(DocumentUserImpl { user: user_session });

        let sender = Arc::new(WsSenderImpl {
            ws_manager: ws_manager.clone(),
        });
        let document_ws_handlers = Arc::new(DocumentWsHandlers::new(sender));
        let receiver = Arc::new(WsMessageReceiverAdaptor(document_ws_handlers.clone()));
        ws_manager.add_receiver(receiver).unwrap();
        (user, document_ws_handlers)
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

        let doc_dir = format!("{}/doc", dir);
        if !Path::new(&doc_dir).exists() {
            let _ = std::fs::create_dir_all(&doc_dir)?;
        }
        Ok(doc_dir)
    }

    fn user_id(&self) -> Result<String, FlowyError> { self.user.user_id() }

    fn token(&self) -> Result<String, FlowyError> { self.user.token() }

    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> { self.user.db_pool() }
}

struct WsSenderImpl {
    ws_manager: Arc<WsManager>,
}

impl DocumentWebSocket for WsSenderImpl {
    fn send(&self, data: WsDocumentData) -> Result<(), FlowyError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WsMessage {
            module: WsModule::Doc,
            data: bytes.to_vec(),
        };
        let sender = self.ws_manager.ws_sender().map_err(internal_error)?;
        sender.send(msg).map_err(internal_error)?;

        Ok(())
    }

    fn subscribe_state_changed(&self) -> WsStateReceiver { self.ws_manager.subscribe_websocket_state() }
}

struct WsMessageReceiverAdaptor(Arc<DocumentWsHandlers>);

impl WsMessageReceiver for WsMessageReceiverAdaptor {
    fn source(&self) -> WsModule { WsModule::Doc }
    fn receive_message(&self, msg: WsMessage) { self.0.did_receive_data(Bytes::from(msg.data)); }
}
