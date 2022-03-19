use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_net::ClientServerConfiguration;
use flowy_net::{
    http_server::document::BlockHttpCloudService, local_server::LocalServer, ws::connection::FlowyWebSocketConnect,
};
use flowy_revision::{RevisionWebSocket, WSStateReceiver};
use flowy_sync::entities::ws_data::ClientRevisionWSData;
use flowy_text_block::{
    errors::{internal_error, FlowyError},
    BlockCloudService, TextBlockManager, TextBlockUser,
};
use flowy_user::services::UserSession;
use futures_core::future::BoxFuture;
use lib_infra::future::BoxResultFuture;
use lib_ws::{WSChannel, WSMessageReceiver, WebSocketRawMessage};
use std::{convert::TryInto, path::Path, sync::Arc};

pub struct TextBlockDepsResolver();
impl TextBlockDepsResolver {
    pub fn resolve(
        local_server: Option<Arc<LocalServer>>,
        ws_conn: Arc<FlowyWebSocketConnect>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
    ) -> Arc<TextBlockManager> {
        let user = Arc::new(BlockUserImpl(user_session));
        let rev_web_socket = Arc::new(TextBlockWebSocket(ws_conn.clone()));
        let cloud_service: Arc<dyn BlockCloudService> = match local_server {
            None => Arc::new(BlockHttpCloudService::new(server_config.clone())),
            Some(local_server) => local_server,
        };

        let manager = Arc::new(TextBlockManager::new(cloud_service, user, rev_web_socket));
        let receiver = Arc::new(DocumentWSMessageReceiverImpl(manager.clone()));
        ws_conn.add_ws_message_receiver(receiver).unwrap();

        manager
    }
}

struct BlockUserImpl(Arc<UserSession>);
impl TextBlockUser for BlockUserImpl {
    fn user_dir(&self) -> Result<String, FlowyError> {
        let dir = self.0.user_dir().map_err(|e| FlowyError::unauthorized().context(e))?;

        let doc_dir = format!("{}/document", dir);
        if !Path::new(&doc_dir).exists() {
            let _ = std::fs::create_dir_all(&doc_dir)?;
        }
        Ok(doc_dir)
    }

    fn user_id(&self) -> Result<String, FlowyError> {
        self.0.user_id()
    }

    fn token(&self) -> Result<String, FlowyError> {
        self.0.token()
    }

    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
        self.0.db_pool()
    }
}

struct TextBlockWebSocket(Arc<FlowyWebSocketConnect>);
impl RevisionWebSocket for TextBlockWebSocket {
    fn send(&self, data: ClientRevisionWSData) -> BoxResultFuture<(), FlowyError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            channel: WSChannel::Document,
            data: bytes.to_vec(),
        };
        let ws_conn = self.0.clone();
        Box::pin(async move {
            match ws_conn.web_socket().await? {
                None => {}
                Some(sender) => {
                    sender.send(msg).map_err(internal_error)?;
                }
            }
            Ok(())
        })
    }

    fn subscribe_state_changed(&self) -> BoxFuture<WSStateReceiver> {
        let ws_conn = self.0.clone();
        Box::pin(async move { ws_conn.subscribe_websocket_state().await })
    }
}

struct DocumentWSMessageReceiverImpl(Arc<TextBlockManager>);
impl WSMessageReceiver for DocumentWSMessageReceiverImpl {
    fn source(&self) -> WSChannel {
        WSChannel::Document
    }
    fn receive_message(&self, msg: WebSocketRawMessage) {
        let handler = self.0.clone();
        tokio::spawn(async move {
            handler.receive_ws_data(Bytes::from(msg.data)).await;
        });
    }
}
