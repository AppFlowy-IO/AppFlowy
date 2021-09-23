use bytes::Bytes;
use flowy_document::{
    errors::DocError,
    module::DocumentUser,
    prelude::{WsDocumentManager, WsDocumentSender},
};

use flowy_document::entities::ws::WsDocumentData;
use flowy_user::{errors::ErrorCode, services::user::UserSession};
use flowy_ws::{WsMessage, WsMessageHandler, WsModule};
use parking_lot::RwLock;
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct DocumentDepsResolver {
    user_session: Arc<UserSession>,
}

impl DocumentDepsResolver {
    pub fn new(user_session: Arc<UserSession>) -> Self { Self { user_session } }

    pub fn split_into(self) -> (Arc<dyn DocumentUser>, Arc<RwLock<WsDocumentManager>>) {
        let user = Arc::new(DocumentUserImpl {
            user: self.user_session.clone(),
        });

        let sender = Arc::new(WsSenderImpl {
            user: self.user_session.clone(),
        });

        let ws_manager = Arc::new(RwLock::new(WsDocumentManager::new(sender)));

        let ws_handler = Arc::new(WsDocumentReceiver { inner: ws_manager.clone() });

        self.user_session.add_ws_handler(ws_handler);

        (user, ws_manager)
    }
}

struct DocumentUserImpl {
    user: Arc<UserSession>,
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

    fn user_id(&self) -> Result<String, DocError> {
        self.user.user_id().map_err(|e| match e.code {
            ErrorCode::InternalError => DocError::internal().context(e.msg),
            _ => DocError::internal().context(e),
        })
    }

    fn token(&self) -> Result<String, DocError> {
        self.user.token().map_err(|e| match e.code {
            ErrorCode::InternalError => DocError::internal().context(e.msg),
            _ => DocError::internal().context(e),
        })
    }
}

struct WsSenderImpl {
    user: Arc<UserSession>,
}

impl WsDocumentSender for WsSenderImpl {
    fn send(&self, data: WsDocumentData) -> Result<(), DocError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WsMessage {
            module: WsModule::Doc,
            data: bytes.to_vec(),
        };
        let _ = self.user.send_ws_msg(msg).map_err(|e| DocError::internal().context(e))?;
        Ok(())
    }
}

struct WsDocumentReceiver {
    inner: Arc<RwLock<WsDocumentManager>>,
}

impl WsMessageHandler for WsDocumentReceiver {
    fn source(&self) -> WsModule { WsModule::Doc }

    fn receive_message(&self, msg: WsMessage) {
        let data = Bytes::from(msg.data);
        self.inner.read().receive_data(data);
    }
}
