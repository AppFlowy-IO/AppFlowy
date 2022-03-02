use bytes::Bytes;
use flowy_block::BlockManager;
use flowy_collaboration::entities::ws_data::ClientRevisionWSData;
use flowy_database::ConnectionPool;
use flowy_folder::{
    controller::FolderManager,
    errors::{internal_error, FlowyError},
    event_map::{FolderCouldServiceV1, WorkspaceDatabase, WorkspaceUser},
};
use flowy_net::ClientServerConfiguration;
use flowy_net::{
    http_server::folder::FolderHttpCloudService, local_server::LocalServer, ws::connection::FlowyWebSocketConnect,
};
use flowy_sync::{RevisionWebSocket, WSStateReceiver};
use flowy_user::services::UserSession;
use futures_core::future::BoxFuture;
use lib_infra::future::BoxResultFuture;
use lib_ws::{WSChannel, WSMessageReceiver, WebSocketRawMessage};
use std::{convert::TryInto, sync::Arc};

pub struct FolderDepsResolver();
impl FolderDepsResolver {
    pub async fn resolve(
        local_server: Option<Arc<LocalServer>>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
        document_manager: &Arc<BlockManager>,
        ws_conn: Arc<FlowyWebSocketConnect>,
    ) -> Arc<FolderManager> {
        let user: Arc<dyn WorkspaceUser> = Arc::new(WorkspaceUserImpl(user_session.clone()));
        let database: Arc<dyn WorkspaceDatabase> = Arc::new(WorkspaceDatabaseImpl(user_session));
        let web_socket = Arc::new(FolderWebSocket(ws_conn.clone()));
        let cloud_service: Arc<dyn FolderCouldServiceV1> = match local_server {
            None => Arc::new(FolderHttpCloudService::new(server_config.clone())),
            Some(local_server) => local_server,
        };

        let folder_manager = Arc::new(
            FolderManager::new(
                user.clone(),
                cloud_service,
                database,
                document_manager.clone(),
                web_socket,
            )
            .await,
        );

        if let (Ok(user_id), Ok(token)) = (user.user_id(), user.token()) {
            match folder_manager.initialize(&user_id, &token).await {
                Ok(_) => {}
                Err(e) => tracing::error!("Initialize folder manager failed: {}", e),
            }
        }

        let receiver = Arc::new(FolderWSMessageReceiverImpl(folder_manager.clone()));
        ws_conn.add_ws_message_receiver(receiver).unwrap();

        folder_manager
    }
}

struct WorkspaceDatabaseImpl(Arc<UserSession>);
impl WorkspaceDatabase for WorkspaceDatabaseImpl {
    fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
        self.0.db_pool().map_err(|e| FlowyError::internal().context(e))
    }
}

struct WorkspaceUserImpl(Arc<UserSession>);
impl WorkspaceUser for WorkspaceUserImpl {
    fn user_id(&self) -> Result<String, FlowyError> {
        self.0.user_id().map_err(|e| FlowyError::internal().context(e))
    }

    fn token(&self) -> Result<String, FlowyError> {
        self.0.token().map_err(|e| FlowyError::internal().context(e))
    }
}

struct FolderWebSocket(Arc<FlowyWebSocketConnect>);
impl RevisionWebSocket for FolderWebSocket {
    fn send(&self, data: ClientRevisionWSData) -> BoxResultFuture<(), FlowyError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            channel: WSChannel::Folder,
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

struct FolderWSMessageReceiverImpl(Arc<FolderManager>);
impl WSMessageReceiver for FolderWSMessageReceiverImpl {
    fn source(&self) -> WSChannel {
        WSChannel::Folder
    }
    fn receive_message(&self, msg: WebSocketRawMessage) {
        let handler = self.0.clone();
        tokio::spawn(async move {
            handler.did_receive_ws_data(Bytes::from(msg.data)).await;
        });
    }
}
