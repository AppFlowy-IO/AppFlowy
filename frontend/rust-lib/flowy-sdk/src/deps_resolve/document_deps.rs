use backend_service::configuration::ClientServerConfiguration;
use bytes::Bytes;
use flowy_collaboration::entities::ws_data::ClientRevisionWSData;
use flowy_database::ConnectionPool;
use flowy_document::{
    errors::{internal_error, FlowyError},
    DocumentCloudService,
    DocumentUser,
    FlowyDocumentManager,
};
use flowy_net::{
    http_server::document::DocumentHttpCloudService,
    local_server::LocalServer,
    ws::connection::FlowyWebSocketConnect,
};
use flowy_sync::{RevisionWebSocket, WSStateReceiver};
use flowy_user::services::UserSession;
use lib_ws::{WSChannel, WSMessageReceiver, WebSocketRawMessage};
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct DocumentDepsResolver();
impl DocumentDepsResolver {
    pub fn resolve(
        local_server: Option<Arc<LocalServer>>,
        ws_conn: Arc<FlowyWebSocketConnect>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
    ) -> Arc<FlowyDocumentManager> {
        let user = Arc::new(DocumentUserImpl(user_session));
        let ws_sender = Arc::new(DocumentWebSocketImpl(ws_conn.clone()));
        let cloud_service: Arc<dyn DocumentCloudService> = match local_server {
            None => Arc::new(DocumentHttpCloudService::new(server_config.clone())),
            Some(local_server) => local_server,
        };

        let manager = Arc::new(FlowyDocumentManager::new(cloud_service, user, ws_sender));
        let receiver = Arc::new(DocumentWSMessageReceiverImpl(manager.clone()));
        ws_conn.add_ws_message_receiver(receiver).unwrap();

        manager
    }
}

struct DocumentUserImpl(Arc<UserSession>);
impl DocumentUser for DocumentUserImpl {
    fn user_dir(&self) -> Result<String, FlowyError> {
        let dir = self.0.user_dir().map_err(|e| FlowyError::unauthorized().context(e))?;

        let doc_dir = format!("{}/document", dir);
        if !Path::new(&doc_dir).exists() {
            let _ = std::fs::create_dir_all(&doc_dir)?;
        }
        Ok(doc_dir)
    }

    fn user_id(&self) -> Result<String, FlowyError> { self.0.user_id() }

    fn token(&self) -> Result<String, FlowyError> { self.0.token() }

    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> { self.0.db_pool() }
}

struct DocumentWebSocketImpl(Arc<FlowyWebSocketConnect>);
impl RevisionWebSocket for DocumentWebSocketImpl {
    fn send(&self, data: ClientRevisionWSData) -> Result<(), FlowyError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            channel: WSChannel::Document,
            data: bytes.to_vec(),
        };
        let sender = self.0.web_socket()?;
        sender.send(msg).map_err(internal_error)?;
        Ok(())
    }

    fn subscribe_state_changed(&self) -> WSStateReceiver { self.0.subscribe_websocket_state() }
}

struct DocumentWSMessageReceiverImpl(Arc<FlowyDocumentManager>);
impl WSMessageReceiver for DocumentWSMessageReceiverImpl {
    fn source(&self) -> WSChannel { WSChannel::Document }
    fn receive_message(&self, msg: WebSocketRawMessage) {
        let handler = self.0.clone();
        tokio::spawn(async move {
            handler.did_receive_ws_data(Bytes::from(msg.data)).await;
        });
    }
}
