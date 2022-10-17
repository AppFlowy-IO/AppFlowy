use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_document::DocumentManager;
use flowy_folder::entities::{ViewDataTypePB, ViewLayoutTypePB};
use flowy_folder::manager::{ViewDataProcessor, ViewDataProcessorMap};
use flowy_folder::{
    errors::{internal_error, FlowyError},
    event_map::{FolderCouldServiceV1, WorkspaceDatabase, WorkspaceUser},
    manager::FolderManager,
};
use flowy_grid::entities::GridLayout;
use flowy_grid::manager::{make_grid_view_data, GridManager};
use flowy_grid::util::{make_default_board, make_default_grid};
use flowy_grid_data_model::revision::BuildGridContext;
use flowy_net::ClientServerConfiguration;
use flowy_net::{
    http_server::folder::FolderHttpCloudService, local_server::LocalServer, ws::connection::FlowyWebSocketConnect,
};
use flowy_revision::{RevisionWebSocket, WSStateReceiver};
use flowy_sync::client_document::default::initial_document_str;
use flowy_sync::entities::revision::{RepeatedRevision, Revision};
use flowy_sync::entities::ws_data::ClientRevisionWSData;
use flowy_user::services::UserSession;
use futures_core::future::BoxFuture;
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ws::{WSChannel, WSMessageReceiver, WebSocketRawMessage};
use std::collections::HashMap;
use std::convert::TryFrom;
use std::{convert::TryInto, sync::Arc};

pub struct FolderDepsResolver();
impl FolderDepsResolver {
    pub async fn resolve(
        local_server: Option<Arc<LocalServer>>,
        user_session: Arc<UserSession>,
        server_config: &ClientServerConfiguration,
        ws_conn: &Arc<FlowyWebSocketConnect>,
        text_block_manager: &Arc<DocumentManager>,
        grid_manager: &Arc<GridManager>,
    ) -> Arc<FolderManager> {
        let user: Arc<dyn WorkspaceUser> = Arc::new(WorkspaceUserImpl(user_session.clone()));
        let database: Arc<dyn WorkspaceDatabase> = Arc::new(WorkspaceDatabaseImpl(user_session));
        let web_socket = Arc::new(FolderRevisionWebSocket(ws_conn.clone()));
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
    text_block_manager: Arc<DocumentManager>,
    grid_manager: Arc<GridManager>,
) -> ViewDataProcessorMap {
    let mut map: HashMap<ViewDataTypePB, Arc<dyn ViewDataProcessor + Send + Sync>> = HashMap::new();

    let block_data_impl = DocumentViewDataProcessor(text_block_manager);
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

struct FolderRevisionWebSocket(Arc<FlowyWebSocketConnect>);
impl RevisionWebSocket for FolderRevisionWebSocket {
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

struct DocumentViewDataProcessor(Arc<DocumentManager>);
impl ViewDataProcessor for DocumentViewDataProcessor {
    fn initialize(&self) -> FutureResult<(), FlowyError> {
        let manager = self.0.clone();
        FutureResult::new(async move { manager.init() })
    }

    fn create_container(
        &self,
        user_id: &str,
        view_id: &str,
        layout: ViewLayoutTypePB,
        delta_data: Bytes,
    ) -> FutureResult<(), FlowyError> {
        // Only accept Document type
        debug_assert_eq!(layout, ViewLayoutTypePB::Document);
        let repeated_revision: RepeatedRevision = Revision::initial_revision(user_id, view_id, delta_data).into();
        let view_id = view_id.to_string();
        let manager = self.0.clone();
        FutureResult::new(async move {
            let _ = manager.create_document(view_id, repeated_revision).await?;
            Ok(())
        })
    }

    fn close_container(&self, view_id: &str) -> FutureResult<(), FlowyError> {
        let manager = self.0.clone();
        let view_id = view_id.to_string();
        FutureResult::new(async move {
            let _ = manager.close_document_editor(view_id)?;
            Ok(())
        })
    }

    fn get_view_data(&self, view_id: &str) -> FutureResult<Bytes, FlowyError> {
        let view_id = view_id.to_string();
        let manager = self.0.clone();
        FutureResult::new(async move {
            let editor = manager.open_document_editor(view_id).await?;
            let delta_bytes = Bytes::from(editor.get_operations_str().await?);
            Ok(delta_bytes)
        })
    }

    fn create_default_view(
        &self,
        user_id: &str,
        view_id: &str,
        layout: ViewLayoutTypePB,
    ) -> FutureResult<Bytes, FlowyError> {
        debug_assert_eq!(layout, ViewLayoutTypePB::Document);
        let user_id = user_id.to_string();
        let view_id = view_id.to_string();
        let manager = self.0.clone();
        FutureResult::new(async move {
            let view_data = initial_document_str();
            let delta_data = Bytes::from(view_data);
            let repeated_revision: RepeatedRevision =
                Revision::initial_revision(&user_id, &view_id, delta_data.clone()).into();
            let _ = manager.create_document(view_id, repeated_revision).await?;
            Ok(delta_data)
        })
    }

    fn create_view_from_delta_data(
        &self,
        _user_id: &str,
        _view_id: &str,
        data: Vec<u8>,
        layout: ViewLayoutTypePB,
    ) -> FutureResult<Bytes, FlowyError> {
        debug_assert_eq!(layout, ViewLayoutTypePB::Document);
        FutureResult::new(async move { Ok(Bytes::from(data)) })
    }

    fn data_type(&self) -> ViewDataTypePB {
        ViewDataTypePB::Text
    }
}

struct GridViewDataProcessor(Arc<GridManager>);
impl ViewDataProcessor for GridViewDataProcessor {
    fn initialize(&self) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn create_container(
        &self,
        user_id: &str,
        view_id: &str,
        _layout: ViewLayoutTypePB,
        delta_data: Bytes,
    ) -> FutureResult<(), FlowyError> {
        let repeated_revision: RepeatedRevision = Revision::initial_revision(user_id, view_id, delta_data).into();
        let view_id = view_id.to_string();
        let grid_manager = self.0.clone();
        FutureResult::new(async move {
            let _ = grid_manager.create_grid(view_id, repeated_revision).await?;
            Ok(())
        })
    }

    fn close_container(&self, view_id: &str) -> FutureResult<(), FlowyError> {
        let grid_manager = self.0.clone();
        let view_id = view_id.to_string();
        FutureResult::new(async move {
            let _ = grid_manager.close_grid(view_id).await?;
            Ok(())
        })
    }

    fn get_view_data(&self, view_id: &str) -> FutureResult<Bytes, FlowyError> {
        let view_id = view_id.to_string();
        let grid_manager = self.0.clone();
        FutureResult::new(async move {
            let editor = grid_manager.open_grid(view_id).await?;
            let delta_bytes = editor.duplicate_grid().await?;
            Ok(delta_bytes.into())
        })
    }

    fn create_default_view(
        &self,
        user_id: &str,
        view_id: &str,
        layout: ViewLayoutTypePB,
    ) -> FutureResult<Bytes, FlowyError> {
        let (build_context, layout) = match layout {
            ViewLayoutTypePB::Grid => (make_default_grid(), GridLayout::Table),
            ViewLayoutTypePB::Board => (make_default_board(), GridLayout::Board),
            ViewLayoutTypePB::Document => {
                return FutureResult::new(async move {
                    Err(FlowyError::internal().context(format!("Can't handle {:?} layout type", layout)))
                });
            }
        };

        let user_id = user_id.to_string();
        let view_id = view_id.to_string();
        let grid_manager = self.0.clone();
        FutureResult::new(
            async move { make_grid_view_data(&user_id, &view_id, layout, grid_manager, build_context).await },
        )
    }

    fn create_view_from_delta_data(
        &self,
        user_id: &str,
        view_id: &str,
        data: Vec<u8>,
        layout: ViewLayoutTypePB,
    ) -> FutureResult<Bytes, FlowyError> {
        let user_id = user_id.to_string();
        let view_id = view_id.to_string();
        let grid_manager = self.0.clone();

        let layout = match layout {
            ViewLayoutTypePB::Grid => GridLayout::Table,
            ViewLayoutTypePB::Board => GridLayout::Board,
            ViewLayoutTypePB::Document => {
                return FutureResult::new(async move {
                    Err(FlowyError::internal().context(format!("Can't handle {:?} layout type", layout)))
                });
            }
        };

        FutureResult::new(async move {
            let bytes = Bytes::from(data);
            let build_context = BuildGridContext::try_from(bytes)?;
            make_grid_view_data(&user_id, &view_id, layout, grid_manager, build_context).await
        })
    }

    fn data_type(&self) -> ViewDataTypePB {
        ViewDataTypePB::Database
    }
}
