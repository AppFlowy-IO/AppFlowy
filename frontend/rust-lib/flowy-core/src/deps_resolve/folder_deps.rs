use bytes::Bytes;
use flowy_sqlite::ConnectionPool;

use database_model::BuildDatabaseContext;
use flowy_client_ws::FlowyWebSocketConnect;
use flowy_database::entities::LayoutTypePB;
use flowy_database::manager::{create_new_database, link_existing_database, DatabaseManager};
use flowy_database::util::{make_default_board, make_default_calendar, make_default_grid};
use flowy_document::editor::make_transaction_from_document_content;
use flowy_document::DocumentManager;

use flowy_folder::entities::{ViewDataFormatPB, ViewLayoutTypePB, ViewPB};
use flowy_folder::manager::{ViewDataProcessor, ViewDataProcessorMap};
use flowy_folder::{
  errors::{internal_error, FlowyError},
  event_map::{FolderCouldServiceV1, WorkspaceDatabase, WorkspaceUser},
  manager::FolderManager,
};
use flowy_net::ClientServerConfiguration;
use flowy_net::{http_server::folder::FolderHttpCloudService, local_server::LocalServer};
use flowy_revision::{RevisionWebSocket, WSStateReceiver};
use flowy_user::services::UserSession;
use futures_core::future::BoxFuture;
use lib_infra::future::{BoxResultFuture, FutureResult};
use lib_ws::{WSChannel, WSMessageReceiver, WebSocketRawMessage};
use revision_model::Revision;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::{convert::TryInto, sync::Arc};
use ws_model::ws_revision::ClientRevisionWSData;

pub struct FolderDepsResolver();
impl FolderDepsResolver {
  pub async fn resolve(
    local_server: Option<Arc<LocalServer>>,
    user_session: Arc<UserSession>,
    server_config: &ClientServerConfiguration,
    ws_conn: &Arc<FlowyWebSocketConnect>,
    text_block_manager: &Arc<DocumentManager>,
    database_manager: &Arc<DatabaseManager>,
  ) -> Arc<FolderManager> {
    let user: Arc<dyn WorkspaceUser> = Arc::new(WorkspaceUserImpl(user_session.clone()));
    let database: Arc<dyn WorkspaceDatabase> = Arc::new(WorkspaceDatabaseImpl(user_session));
    let web_socket = Arc::new(FolderRevisionWebSocket(ws_conn.clone()));
    let cloud_service: Arc<dyn FolderCouldServiceV1> = match local_server {
      None => Arc::new(FolderHttpCloudService::new(server_config.clone())),
      Some(local_server) => local_server,
    };

    let view_data_processor =
      make_view_data_processor(text_block_manager.clone(), database_manager.clone());
    let folder_manager = Arc::new(
      FolderManager::new(
        user.clone(),
        cloud_service,
        database,
        view_data_processor,
        web_socket,
      )
      .await,
    );

    // if let (Ok(user_id), Ok(token)) = (user.user_id(), user.token()) {
    //   match folder_manager.initialize(&user_id, &token).await {
    //     Ok(_) => {},
    //     Err(e) => tracing::error!("Initialize folder manager failed: {}", e),
    //   }
    // }

    let receiver = Arc::new(FolderWSMessageReceiverImpl(folder_manager.clone()));
    ws_conn.add_ws_message_receiver(receiver).unwrap();
    folder_manager
  }
}

fn make_view_data_processor(
  document_manager: Arc<DocumentManager>,
  database_manager: Arc<DatabaseManager>,
) -> ViewDataProcessorMap {
  let mut map: HashMap<ViewDataFormatPB, Arc<dyn ViewDataProcessor + Send + Sync>> = HashMap::new();

  let document_processor = Arc::new(DocumentViewDataProcessor(document_manager));
  document_processor
    .data_types()
    .into_iter()
    .for_each(|data_type| {
      map.insert(data_type, document_processor.clone());
    });

  let grid_data_impl = Arc::new(DatabaseViewDataProcessor(database_manager));
  grid_data_impl
    .data_types()
    .into_iter()
    .for_each(|data_type| {
      map.insert(data_type, grid_data_impl.clone());
    });

  Arc::new(map)
}

struct WorkspaceDatabaseImpl(Arc<UserSession>);
impl WorkspaceDatabase for WorkspaceDatabaseImpl {
  fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError> {
    self
      .0
      .db_pool()
      .map_err(|e| FlowyError::internal().context(e))
  }
}

struct WorkspaceUserImpl(Arc<UserSession>);
impl WorkspaceUser for WorkspaceUserImpl {
  fn user_id(&self) -> Result<String, FlowyError> {
    self
      .0
      .user_id()
      .map_err(|e| FlowyError::internal().context(e))
  }

  fn token(&self) -> Result<String, FlowyError> {
    self
      .0
      .token()
      .map_err(|e| FlowyError::internal().context(e))
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
        None => {},
        Some(sender) => {
          sender.send(msg).map_err(internal_error)?;
        },
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
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.close_document_editor(view_id).await?;
      Ok(())
    })
  }

  fn get_view_data(&self, view: &ViewPB) -> FutureResult<Bytes, FlowyError> {
    let view_id = view.id.clone();
    let manager = self.0.clone();
    FutureResult::new(async move {
      let editor = manager.open_document_editor(view_id).await?;
      let document_data = Bytes::from(editor.duplicate().await?);
      Ok(document_data)
    })
  }

  fn create_view_with_build_in_data(
    &self,
    user_id: &str,
    view_id: &str,
    _name: &str,
    layout: ViewLayoutTypePB,
    _data_format: ViewDataFormatPB,
    _ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayoutTypePB::Document);
    let _user_id = user_id.to_string();
    let view_id = view_id.to_string();
    let manager = self.0.clone();
    let document_content = self.0.initial_document_content();
    FutureResult::new(async move {
      let delta_data = Bytes::from(document_content);
      let revision = Revision::initial_revision(&view_id, delta_data);
      manager.create_document(view_id, vec![revision]).await?;
      Ok(())
    })
  }

  fn create_view_with_custom_data(
    &self,
    _user_id: &str,
    view_id: &str,
    _name: &str,
    data: Vec<u8>,
    layout: ViewLayoutTypePB,
    _ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayoutTypePB::Document);
    let view_data = match String::from_utf8(data) {
      Ok(content) => match make_transaction_from_document_content(&content) {
        Ok(transaction) => transaction.to_bytes().unwrap_or_else(|_| vec![]),
        Err(_) => vec![],
      },
      Err(_) => vec![],
    };

    let revision = Revision::initial_revision(view_id, Bytes::from(view_data));
    let view_id = view_id.to_string();
    let manager = self.0.clone();

    FutureResult::new(async move {
      manager.create_document(view_id, vec![revision]).await?;
      Ok(())
    })
  }

  fn data_types(&self) -> Vec<ViewDataFormatPB> {
    vec![ViewDataFormatPB::DeltaFormat, ViewDataFormatPB::NodeFormat]
  }
}

struct DatabaseViewDataProcessor(Arc<DatabaseManager>);
impl ViewDataProcessor for DatabaseViewDataProcessor {
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      database_manager.close_database_view(view_id).await?;
      Ok(())
    })
  }

  fn get_view_data(&self, view: &ViewPB) -> FutureResult<Bytes, FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view.id.clone();
    FutureResult::new(async move {
      let editor = database_manager.open_database_view(&view_id).await?;
      let delta_bytes = editor.duplicate_database(&view_id).await?;
      Ok(delta_bytes.into())
    })
  }

  /// Create a database view with build-in data.
  /// If the ext contains the {"database_id": "xx"}, then it will link to
  /// the existing database. The data of the database will be shared within
  /// these references views.
  fn create_view_with_build_in_data(
    &self,
    _user_id: &str,
    view_id: &str,
    name: &str,
    layout: ViewLayoutTypePB,
    data_format: ViewDataFormatPB,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(data_format, ViewDataFormatPB::DatabaseFormat);
    let view_id = view_id.to_string();
    let name = name.to_string();
    let database_manager = self.0.clone();
    match DatabaseExtParams::from_map(ext).map(|params| params.database_id) {
      None => {
        let (build_context, layout) = match layout {
          ViewLayoutTypePB::Grid => (make_default_grid(), LayoutTypePB::Grid),
          ViewLayoutTypePB::Board => (make_default_board(), LayoutTypePB::Board),
          ViewLayoutTypePB::Calendar => (make_default_calendar(), LayoutTypePB::Calendar),
          ViewLayoutTypePB::Document => {
            return FutureResult::new(async move {
              Err(FlowyError::internal().context(format!("Can't handle {:?} layout type", layout)))
            });
          },
        };
        FutureResult::new(async move {
          create_new_database(&view_id, name, layout, database_manager, build_context).await
        })
      },
      Some(database_id) => {
        let layout = layout_type_from_view_layout(layout);
        FutureResult::new(async move {
          link_existing_database(&view_id, name, &database_id, layout, database_manager).await
        })
      },
    }
  }

  /// Create a database view with custom data.
  /// If the ext contains the {"database_id": "xx"}, then it will link
  /// to the existing database. The data of the database will be shared
  /// within these references views.
  fn create_view_with_custom_data(
    &self,
    _user_id: &str,
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayoutTypePB,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    let view_id = view_id.to_string();
    let database_manager = self.0.clone();
    let layout = layout_type_from_view_layout(layout);
    let name = name.to_string();
    match DatabaseExtParams::from_map(ext).map(|params| params.database_id) {
      None => FutureResult::new(async move {
        let bytes = Bytes::from(data);
        let build_context = BuildDatabaseContext::try_from(bytes)?;
        let _ = create_new_database(&view_id, name, layout, database_manager, build_context).await;
        Ok(())
      }),
      Some(database_id) => FutureResult::new(async move {
        link_existing_database(&view_id, name, &database_id, layout, database_manager).await
      }),
    }
  }

  fn data_types(&self) -> Vec<ViewDataFormatPB> {
    vec![ViewDataFormatPB::DatabaseFormat]
  }
}

pub fn layout_type_from_view_layout(layout: ViewLayoutTypePB) -> LayoutTypePB {
  match layout {
    ViewLayoutTypePB::Grid => LayoutTypePB::Grid,
    ViewLayoutTypePB::Board => LayoutTypePB::Board,
    ViewLayoutTypePB::Calendar => LayoutTypePB::Calendar,
    ViewLayoutTypePB::Document => LayoutTypePB::Grid,
  }
}

#[derive(Debug, serde::Deserialize)]
struct DatabaseExtParams {
  database_id: String,
}

impl DatabaseExtParams {
  pub fn from_map(map: HashMap<String, String>) -> Option<Self> {
    let value = serde_json::to_value(map).ok()?;
    serde_json::from_value::<Self>(value).ok()
  }
}
