use bytes::Bytes;
use flowy_collaboration::entities::ws::WsDocumentData;
use flowy_database::ConnectionPool;
use flowy_document::{
    errors::{internal_error, DocError},
    module::DocumentUser,
    services::ws::{DocumentWebSocket, WsDocumentManager, WsStateReceiver},
};
use flowy_net::services::ws::WsManager;
use flowy_user::{
    errors::{ErrorCode, UserError},
    services::user::UserSession,
};
use lib_ws::{WsMessage, WsMessageHandler, WsModule};
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct DocumentDepsResolver();
impl DocumentDepsResolver {
    pub fn resolve(
        ws_manager: Arc<WsManager>,
        user_session: Arc<UserSession>,
    ) -> (Arc<dyn DocumentUser>, Arc<WsDocumentManager>) {
        let user = Arc::new(DocumentUserImpl {
            user: user_session.clone(),
        });

        let sender = Arc::new(WsSenderImpl {
            ws_manager: ws_manager.clone(),
        });
        let ws_doc = Arc::new(WsDocumentManager::new(sender));
        let ws_handler = Arc::new(DocumentWsMessageReceiver { inner: ws_doc.clone() });
        ws_manager.add_handler(ws_handler);
        (user, ws_doc)
    }
}

struct DocumentUserImpl {
    user: Arc<UserSession>,
}

impl DocumentUserImpl {}

fn map_user_error(error: UserError) -> DocError {
    match ErrorCode::from_i32(error.code) {
        ErrorCode::InternalError => DocError::internal().context(error.msg),
        _ => DocError::internal().context(error),
    }
}

impl DocumentUser for DocumentUserImpl {
    fn user_dir(&self) -> Result<String, DocError> {
        let dir = self.user.user_dir().map_err(|e| DocError::unauthorized().context(e))?;

        let doc_dir = format!("{}/doc", dir);
        if !Path::new(&doc_dir).exists() {
            let _ = std::fs::create_dir_all(&doc_dir)?;
        }
        Ok(doc_dir)
    }

    fn user_id(&self) -> Result<String, DocError> { self.user.user_id().map_err(map_user_error) }

    fn token(&self) -> Result<String, DocError> { self.user.token().map_err(map_user_error) }

    fn db_pool(&self) -> Result<Arc<ConnectionPool>, DocError> { self.user.db_pool().map_err(map_user_error) }
}

struct WsSenderImpl {
    ws_manager: Arc<WsManager>,
}

impl DocumentWebSocket for WsSenderImpl {
    fn send(&self, data: WsDocumentData) -> Result<(), DocError> {
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

struct DocumentWsMessageReceiver {
    inner: Arc<WsDocumentManager>,
}

impl WsMessageHandler for DocumentWsMessageReceiver {
    fn source(&self) -> WsModule { WsModule::Doc }

    fn receive_message(&self, msg: WsMessage) {
        let data = Bytes::from(msg.data);
        self.inner.did_receive_ws_data(data);
    }
}
