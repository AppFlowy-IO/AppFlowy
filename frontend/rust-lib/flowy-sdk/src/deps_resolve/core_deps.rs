use backend_service::configuration::ClientServerConfiguration;
use bytes::Bytes;
use flowy_collaboration::entities::ws_data::ClientRevisionWSData;
use flowy_core::{
    controller::FolderManager,
    errors::{internal_error, FlowyError},
    module::{init_folder, WorkspaceCloudService, WorkspaceDatabase, WorkspaceUser},
};
use flowy_database::ConnectionPool;
use flowy_document::context::DocumentContext;
use flowy_net::{
    http_server::core::CoreHttpCloudService,
    local_server::LocalServer,
    ws::connection::FlowyWebSocketConnect,
};
use flowy_sync::{RevisionWebSocket, WSStateReceiver};
use flowy_user::services::UserSession;
use lib_ws::{WSMessageReceiver, WSModule, WebSocketRawMessage};
use std::{convert::TryInto, sync::Arc};

pub struct CoreDepsResolver();
impl CoreDepsResolver {
    pub fn resolve(
        local_server: Option<Arc<LocalServer>>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
        flowy_document: &Arc<DocumentContext>,
        ws_conn: Arc<FlowyWebSocketConnect>,
    ) -> Arc<FolderManager> {
        let user: Arc<dyn WorkspaceUser> = Arc::new(WorkspaceUserImpl(user_session.clone()));
        let database: Arc<dyn WorkspaceDatabase> = Arc::new(WorkspaceDatabaseImpl(user_session));
        let ws_sender = Arc::new(FolderWebSocketImpl(ws_conn.clone()));
        let cloud_service: Arc<dyn WorkspaceCloudService> = match local_server {
            None => Arc::new(CoreHttpCloudService::new(server_config.clone())),
            Some(local_server) => local_server,
        };

        let folder_manager = init_folder(user, database, flowy_document.clone(), cloud_service, ws_sender);
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
    fn user_id(&self) -> Result<String, FlowyError> { self.0.user_id().map_err(|e| FlowyError::internal().context(e)) }

    fn token(&self) -> Result<String, FlowyError> { self.0.token().map_err(|e| FlowyError::internal().context(e)) }
}

struct FolderWebSocketImpl(Arc<FlowyWebSocketConnect>);
impl RevisionWebSocket for FolderWebSocketImpl {
    fn send(&self, data: ClientRevisionWSData) -> Result<(), FlowyError> {
        let bytes: Bytes = data.try_into().unwrap();
        let msg = WebSocketRawMessage {
            module: WSModule::Folder,
            data: bytes.to_vec(),
        };
        let sender = self.0.web_socket()?;
        sender.send(msg).map_err(internal_error)?;
        Ok(())
    }

    fn subscribe_state_changed(&self) -> WSStateReceiver { self.0.subscribe_websocket_state() }
}

struct FolderWSMessageReceiverImpl(Arc<FolderManager>);
impl WSMessageReceiver for FolderWSMessageReceiverImpl {
    fn source(&self) -> WSModule { WSModule::Folder }
    fn receive_message(&self, msg: WebSocketRawMessage) {
        let handler = self.0.clone();
        tokio::spawn(async move {
            handler.did_receive_ws_data(Bytes::from(msg.data)).await;
        });
    }
}
