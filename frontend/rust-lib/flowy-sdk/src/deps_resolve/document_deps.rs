use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_document::{
    errors::{internal_error, DocError},
    module::DocumentUser,
    services::ws::{DocumentWebSocket, WsDocumentManager, WsStateReceiver},
};
use flowy_document_infra::entities::ws::WsDocumentData;
use flowy_user::{
    errors::{ErrorCode, UserError},
    services::user::UserSession,
};
use lib_ws::{WsMessage, WsMessageHandler, WsModule};
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct DocumentDepsResolver {
    user_session: Arc<UserSession>,
}

impl DocumentDepsResolver {
    pub fn new(user_session: Arc<UserSession>) -> Self { Self { user_session } }

    pub fn split_into(self) -> (Arc<dyn DocumentUser>, Arc<WsDocumentManager>) {
        let user = Arc::new(DocumentUserImpl {
            user: self.user_session.clone(),
        });

        let sender = Arc::new(WsSenderImpl {
            user: self.user_session.clone(),
        });
        let ws_manager = Arc::new(WsDocumentManager::new(sender));
        let ws_handler = Arc::new(WsDocumentReceiver {
            inner: ws_manager.clone(),
        });
        self.user_session.add_ws_handler(ws_handler);
        (user, ws_manager)
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
    user: Arc<UserSession>,
}

impl DocumentWebSocket for WsSenderImpl {
    fn send(&self, data: WsDocumentData) -> Result<(), DocError> {
        if cfg!(feature = "http_server") {
            let bytes: Bytes = data.try_into().unwrap();
            let msg = WsMessage {
                module: WsModule::Doc,
                data: bytes.to_vec(),
            };
            let sender = self.user.ws_sender().map_err(internal_error)?;
            sender.send_msg(msg).map_err(internal_error)?;
        }

        Ok(())
    }

    fn state_notify(&self) -> WsStateReceiver { self.user.ws_state_notifier() }
}

struct WsDocumentReceiver {
    inner: Arc<WsDocumentManager>,
}

impl WsMessageHandler for WsDocumentReceiver {
    fn source(&self) -> WsModule { WsModule::Doc }

    fn receive_message(&self, msg: WsMessage) {
        let data = Bytes::from(msg.data);
        self.inner.handle_ws_data(data);
    }
}
