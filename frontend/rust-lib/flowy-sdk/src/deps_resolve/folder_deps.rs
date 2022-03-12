use bytes::Bytes;
use flowy_block::TextBlockManager;
use flowy_collaboration::client_document::default::initial_quill_delta_string;
use flowy_collaboration::client_grid::make_default_grid;
use flowy_collaboration::entities::revision::{RepeatedRevision, Revision};
use flowy_collaboration::entities::ws_data::ClientRevisionWSData;
use flowy_database::ConnectionPool;
use flowy_folder::manager::{ViewDataProcessor, ViewDataProcessorMap};
use flowy_folder::prelude::ViewDataType;
use flowy_folder::{
    errors::{internal_error, FlowyError},
    event_map::{FolderCouldServiceV1, WorkspaceDatabase, WorkspaceUser},
    manager::FolderManager,
};
use flowy_grid::manager::GridManager;
use flowy_net::ClientServerConfiguration;
use flowy_net::{
    http_server::folder::FolderHttpCloudService, local_server::LocalServer, ws::connection::FlowyWebSocketConnect,
};
use flowy_sync::{RevisionWebSocket, WSStateReceiver};
use flowy_user::services::UserSession;
use futures_core::future::BoxFuture;
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ws::{WSChannel, WSMessageReceiver, WebSocketRawMessage};
use std::collections::HashMap;
use std::{convert::TryInto, sync::Arc};

pub struct FolderDepsResolver();
impl FolderDepsResolver {
    pub async fn resolve(
        local_server: Option<Arc<LocalServer>>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
        ws_conn: &Arc<FlowyWebSocketConnect>,
        text_block_manager: &Arc<TextBlockManager>,
        grid_manager: &Arc<GridManager>,
    ) -> Arc<FolderManager> {
        let user: Arc<dyn WorkspaceUser> = Arc::new(WorkspaceUserImpl(user_session.clone()));
        let database: Arc<dyn WorkspaceDatabase> = Arc::new(WorkspaceDatabaseImpl(user_session));
        let web_socket = Arc::new(FolderWebSocket(ws_conn.clone()));
        let cloud_service: Arc<dyn FolderCouldServiceV1> = match local_server {
            None => Arc::new(FolderHttpCloudService::new(server_config.clone())),
            Some(local_server) => local_server,
        };

        let view_data_processor = make_view_data_processor(text_block_manager.clone(), grid_manager.clone());
        let folder_manager =
            Arc::new(FolderManager::new(user.clone(), cloud_service, database, view_data_processor, web_socket).await);

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

fn make_view_data_processor(
    text_block_manager: Arc<TextBlockManager>,
    grid_manager: Arc<GridManager>,
) -> ViewDataProcessorMap {
    let mut map: HashMap<ViewDataType, Arc<dyn ViewDataProcessor + Send + Sync>> = HashMap::new();

    let block_data_impl = TextBlockViewDataProcessor(text_block_manager);
    map.insert(block_data_impl.data_type(), Arc::new(block_data_impl));

    let grid_data_impl = GridViewDataProcessor(grid_manager);
    map.insert(grid_data_impl.data_type(), Arc::new(grid_data_impl));

    Arc::new(map)
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

struct TextBlockViewDataProcessor(Arc<TextBlockManager>);
impl ViewDataProcessor for TextBlockViewDataProcessor {
    fn initialize(&self) -> FutureResult<(), FlowyError> {
        let manager = self.0.clone();
        FutureResult::new(async move { manager.init() })
    }

    fn create_container(&self, user_id: &str, view_id: &str, delta_data: Bytes) -> FutureResult<(), FlowyError> {
        let repeated_revision: RepeatedRevision = Revision::initial_revision(user_id, view_id, delta_data).into();
        let view_id = view_id.to_string();
        let manager = self.0.clone();
        FutureResult::new(async move {
            let _ = manager.create_block(view_id, repeated_revision).await?;
            Ok(())
        })
    }

    fn delete_container(&self, view_id: &str) -> FutureResult<(), FlowyError> {
        let manager = self.0.clone();
        let view_id = view_id.to_string();
        FutureResult::new(async move {
            let _ = manager.delete_block(view_id)?;
            Ok(())
        })
    }

    fn close_container(&self, view_id: &str) -> FutureResult<(), FlowyError> {
        let manager = self.0.clone();
        let view_id = view_id.to_string();
        FutureResult::new(async move {
            let _ = manager.close_block(view_id)?;
            Ok(())
        })
    }

    fn delta_str(&self, view_id: &str) -> FutureResult<String, FlowyError> {
        let view_id = view_id.to_string();
        let manager = self.0.clone();
        FutureResult::new(async move {
            let editor = manager.open_block(view_id).await?;
            let delta_str = editor.delta_str().await?;
            Ok(delta_str)
        })
    }

    fn create_default_view(&self, user_id: &str, view_id: &str) -> FutureResult<String, FlowyError> {
        let user_id = user_id.to_string();
        let view_id = view_id.to_string();
        let manager = self.0.clone();
        FutureResult::new(async move {
            let view_data = initial_quill_delta_string();
            let delta_data = Bytes::from(view_data.clone());
            let repeated_revision: RepeatedRevision = Revision::initial_revision(&user_id, &view_id, delta_data).into();
            let _ = manager.create_block(view_id, repeated_revision).await?;
            Ok(view_data)
        })
    }

    fn data_type(&self) -> ViewDataType {
        ViewDataType::TextBlock
    }
}

struct GridViewDataProcessor(Arc<GridManager>);
impl ViewDataProcessor for GridViewDataProcessor {
    fn initialize(&self) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_container(&self, user_id: &str, view_id: &str, delta_data: Bytes) -> FutureResult<(), FlowyError> {
        let repeated_revision: RepeatedRevision = Revision::initial_revision(user_id, view_id, delta_data).into();
        let view_id = view_id.to_string();
        let grid_manager = self.0.clone();
        FutureResult::new(async move {
            let _ = grid_manager.create_grid(view_id, repeated_revision).await?;
            Ok(())
        })
    }

    fn delete_container(&self, view_id: &str) -> FutureResult<(), FlowyError> {
        let grid_manager = self.0.clone();
        let view_id = view_id.to_string();
        FutureResult::new(async move {
            let _ = grid_manager.delete_grid(view_id)?;
            Ok(())
        })
    }

    fn close_container(&self, view_id: &str) -> FutureResult<(), FlowyError> {
        let grid_manager = self.0.clone();
        let view_id = view_id.to_string();
        FutureResult::new(async move {
            let _ = grid_manager.close_grid(view_id)?;
            Ok(())
        })
    }

    fn delta_str(&self, view_id: &str) -> FutureResult<String, FlowyError> {
        let view_id = view_id.to_string();
        let grid_manager = self.0.clone();
        FutureResult::new(async move {
            let editor = grid_manager.open_grid(view_id).await?;
            let delta_str = editor.delta_str().await;
            Ok(delta_str)
        })
    }

    fn create_default_view(&self, user_id: &str, view_id: &str) -> FutureResult<String, FlowyError> {
        let info = make_default_grid(view_id);
        let user_id = user_id.to_string();
        let view_id = view_id.to_string();
        let grid_manager = self.0.clone();

        FutureResult::new(async move {
            let grid_delta_data = Bytes::from(info.grid_delta.to_delta_str());
            let repeated_revision: RepeatedRevision =
                Revision::initial_revision(&user_id, &view_id, grid_delta_data).into();
            let _ = grid_manager.create_grid(&view_id, repeated_revision).await?;

            let block_meta_delta_data = Bytes::from(info.grid_block_meta_delta.to_delta_str());
            let repeated_revision: RepeatedRevision =
                Revision::initial_revision(&user_id, &info.block_id, block_meta_delta_data).into();
            let _ = grid_manager
                .create_grid_block_meta(&info.block_id, repeated_revision)
                .await?;

            Ok(info.grid_delta.to_delta_str())
        })
    }

    fn data_type(&self) -> ViewDataType {
        ViewDataType::Grid
    }
}
