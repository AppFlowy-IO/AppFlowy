use bytes::Bytes;
use client_api::entity::ai_dto::CollabType;
use collab_entity::EncodedCollab;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_chat::chat_manager::ChatManager;
use flowy_database2::entities::DatabaseLayoutPB;
use flowy_database2::services::share::csv::CSVFormat;
use flowy_database2::template::{make_default_board, make_default_calendar, make_default_grid};
use flowy_database2::DatabaseManager;
use flowy_document::entities::DocumentDataPB;
use flowy_document::manager::DocumentManager;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use flowy_error::FlowyError;
use flowy_folder::entities::{CreateViewParams, ViewLayoutPB};
use flowy_folder::manager::{FolderManager, FolderUser};
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{
  FolderOperationHandler, FolderOperationHandlers, View, ViewData,
};
use flowy_folder::ViewLayout;
use flowy_folder_pub::folder_builder::NestedViewBuilder;
use flowy_search::folder::indexer::FolderIndexManagerImpl;
use flowy_sqlite::kv::StorePreferences;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_dispatch::prelude::ToBytes;
use lib_infra::future::FutureResult;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;

use crate::integrate::server::ServerProvider;

pub struct FolderDepsResolver();
#[allow(clippy::too_many_arguments)]
impl FolderDepsResolver {
  pub async fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    server_provider: Arc<ServerProvider>,
    folder_indexer: Arc<FolderIndexManagerImpl>,
    store_preferences: Arc<StorePreferences>,
    operation_handlers: FolderOperationHandlers,
  ) -> Arc<FolderManager> {
    let user: Arc<dyn FolderUser> = Arc::new(FolderUserImpl {
      authenticate_user: authenticate_user.clone(),
    });

    Arc::new(
      FolderManager::new(
        user.clone(),
        collab_builder,
        operation_handlers,
        server_provider.clone(),
        folder_indexer,
        store_preferences,
      )
      .unwrap(),
    )
  }
}

pub fn folder_operation_handlers(
  document_manager: Arc<DocumentManager>,
  database_manager: Arc<DatabaseManager>,
  chat_manager: Arc<ChatManager>,
) -> FolderOperationHandlers {
  let mut map: HashMap<ViewLayout, Arc<dyn FolderOperationHandler + Send + Sync>> = HashMap::new();

  let document_folder_operation = Arc::new(DocumentFolderOperation(document_manager));
  map.insert(ViewLayout::Document, document_folder_operation);

  let database_folder_operation = Arc::new(DatabaseFolderOperation(database_manager));
  let chat_folder_operation = Arc::new(ChatFolderOperation(chat_manager));
  map.insert(ViewLayout::Board, database_folder_operation.clone());
  map.insert(ViewLayout::Grid, database_folder_operation.clone());
  map.insert(ViewLayout::Calendar, database_folder_operation);
  map.insert(ViewLayout::Chat, chat_folder_operation);
  Arc::new(map)
}

struct FolderUserImpl {
  authenticate_user: Weak<AuthenticateUser>,
}

impl FolderUserImpl {
  fn upgrade_user(&self) -> Result<Arc<AuthenticateUser>, FlowyError> {
    let user = self
      .authenticate_user
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?;
    Ok(user)
  }
}

impl FolderUser for FolderUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self.upgrade_user()?.user_id()
  }

  fn workspace_id(&self) -> Result<String, FlowyError> {
    self.upgrade_user()?.workspace_id()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self.upgrade_user()?.get_collab_db(uid)
  }
}

struct DocumentFolderOperation(Arc<DocumentManager>);
impl FolderOperationHandler for DocumentFolderOperation {
  fn create_workspace_view(
    &self,
    uid: i64,
    workspace_view_builder: Arc<RwLock<NestedViewBuilder>>,
  ) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    FutureResult::new(async move {
      let mut write_guard = workspace_view_builder.write().await;

      // Create a view named "Getting started" with an icon ⭐️ and the built-in README data.
      // Don't modify this code unless you know what you are doing.
      write_guard
        .with_view_builder(|view_builder| async {
          let view = view_builder
            .with_name("Getting started")
            .with_icon("⭐️")
            .build();
          // create a empty document
          let json_str = include_str!("../../assets/read_me.json");
          let document_pb = JsonToDocumentParser::json_str_to_document(json_str).unwrap();
          manager
            .create_document(uid, &view.parent_view.id, Some(document_pb.into()))
            .await
            .unwrap();
          view
        })
        .await;
      Ok(())
    })
  }

  fn open_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.open_document(&view_id).await?;
      Ok(())
    })
  }

  /// Close the document view.
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.close_document(&view_id).await?;
      Ok(())
    })
  }

  fn delete_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      match manager.delete_document(&view_id).await {
        Ok(_) => tracing::trace!("Delete document: {}", view_id),
        Err(e) => tracing::error!("🔴delete document failed: {}", e),
      }
      Ok(())
    })
  }

  fn duplicate_view(&self, view_id: &str) -> FutureResult<Bytes, FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      let data: DocumentDataPB = manager.get_document_data(&view_id).await?.into();
      let data_bytes = data.into_bytes().map_err(|_| FlowyError::invalid_data())?;
      Ok(data_bytes)
    })
  }

  fn create_view_with_view_data(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(params.layout, ViewLayoutPB::Document);
    let view_id = params.view_id.to_string();
    let manager = self.0.clone();
    FutureResult::new(async move {
      let data = DocumentDataPB::try_from(Bytes::from(params.initial_data))?;
      manager
        .create_document(user_id, &view_id, Some(data.into()))
        .await?;
      Ok(())
    })
  }

  /// Create a view with built-in data.
  fn create_built_in_view(
    &self,
    user_id: i64,
    view_id: &str,
    _name: &str,
    layout: ViewLayout,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayout::Document);
    let view_id = view_id.to_string();
    let manager = self.0.clone();
    FutureResult::new(async move {
      match manager.create_document(user_id, &view_id, None).await {
        Ok(_) => Ok(()),
        Err(err) => {
          if err.is_already_exists() {
            Ok(())
          } else {
            Err(err)
          }
        },
      }
    })
  }

  fn import_from_bytes(
    &self,
    uid: i64,
    view_id: &str,
    _name: &str,
    _import_type: ImportType,
    bytes: Vec<u8>,
  ) -> FutureResult<EncodedCollab, FlowyError> {
    let view_id = view_id.to_string();
    let manager = self.0.clone();
    FutureResult::new(async move {
      let data = DocumentDataPB::try_from(Bytes::from(bytes))?;
      let encoded_collab = manager
        .create_document(uid, &view_id, Some(data.into()))
        .await?;
      Ok(encoded_collab)
    })
  }

  // will implement soon
  fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    _path: String,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move { Ok(()) })
  }
}

struct DatabaseFolderOperation(Arc<DatabaseManager>);
impl FolderOperationHandler for DatabaseFolderOperation {
  fn open_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      database_manager.open_database_view(view_id).await?;
      Ok(())
    })
  }

  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      database_manager.close_database_view(view_id).await?;
      Ok(())
    })
  }

  fn delete_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      match database_manager.delete_database_view(&view_id).await {
        Ok(_) => tracing::trace!("Delete database view: {}", view_id),
        Err(e) => tracing::error!("🔴delete database failed: {}", e),
      }
      Ok(())
    })
  }

  fn duplicate_view(&self, view_id: &str) -> FutureResult<Bytes, FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_owned();
    FutureResult::new(async move {
      let delta_bytes = database_manager.duplicate_database(&view_id).await?;
      Ok(Bytes::from(delta_bytes))
    })
  }

  /// Create a database view with duplicated data.
  /// If the ext contains the {"database_id": "xx"}, then it will link
  /// to the existing database.
  fn create_view_with_view_data(
    &self,
    _user_id: i64,
    params: CreateViewParams,
  ) -> FutureResult<(), FlowyError> {
    match CreateDatabaseExtParams::from_map(params.meta.clone()) {
      None => {
        let database_manager = self.0.clone();
        let view_id = params.view_id.to_string();
        FutureResult::new(async move {
          database_manager
            .create_database_with_database_data(&view_id, params.initial_data)
            .await?;
          Ok(())
        })
      },
      Some(database_params) => {
        let database_manager = self.0.clone();

        let layout = match params.layout {
          ViewLayoutPB::Board => DatabaseLayoutPB::Board,
          ViewLayoutPB::Calendar => DatabaseLayoutPB::Calendar,
          ViewLayoutPB::Grid => DatabaseLayoutPB::Grid,
          ViewLayoutPB::Document | ViewLayoutPB::Chat => {
            return FutureResult::new(async move { Err(FlowyError::not_support()) });
          },
        };
        let name = params.name.to_string();
        let database_view_id = params.view_id.to_string();
        let database_parent_view_id = params.parent_view_id.to_string();

        FutureResult::new(async move {
          database_manager
            .create_linked_view(
              name,
              layout.into(),
              database_params.database_id,
              database_view_id,
              database_parent_view_id,
            )
            .await?;
          Ok(())
        })
      },
    }
  }

  /// Create a database view with build-in data.
  /// If the ext contains the {"database_id": "xx"}, then it will link to
  /// the existing database. The data of the database will be shared within
  /// these references views.
  fn create_built_in_view(
    &self,
    _user_id: i64,
    view_id: &str,
    name: &str,
    layout: ViewLayout,
  ) -> FutureResult<(), FlowyError> {
    let name = name.to_string();
    let database_manager = self.0.clone();
    let data = match layout {
      ViewLayout::Grid => make_default_grid(view_id, &name),
      ViewLayout::Board => make_default_board(view_id, &name),
      ViewLayout::Calendar => make_default_calendar(view_id, &name),
      ViewLayout::Document => {
        return FutureResult::new(async move {
          Err(FlowyError::internal().with_context(format!("Can't handle {:?} layout type", layout)))
        });
      },
      ViewLayout::Chat => {
        // TODO(nathan): AI
        todo!("AI")
      },
    };
    FutureResult::new(async move {
      let result = database_manager.create_database_with_params(data).await;
      match result {
        Ok(_) => Ok(()),
        Err(err) => {
          if err.is_already_exists() {
            Ok(())
          } else {
            Err(err)
          }
        },
      }
    })
  }

  fn import_from_bytes(
    &self,
    _uid: i64,
    view_id: &str,
    _name: &str,
    import_type: ImportType,
    bytes: Vec<u8>,
  ) -> FutureResult<EncodedCollab, FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    let format = match import_type {
      ImportType::CSV => CSVFormat::Original,
      ImportType::HistoryDatabase => CSVFormat::META,
      ImportType::RawDatabase => CSVFormat::META,
      _ => CSVFormat::Original,
    };
    FutureResult::new(async move {
      let content = tokio::task::spawn_blocking(move || {
        String::from_utf8(bytes).map_err(|err| FlowyError::internal().with_context(err))
      })
      .await??;

      let result = database_manager
        .import_csv(view_id, content, format)
        .await?;
      let database = result.database;
      let encoded_collab = database
        .into_inner()
        .get_collab()
        .lock()
        .encode_collab_v1(|collab| {
          CollabType::Database
            .validate_require_data(collab)
            .map_err(|_| DatabaseError::NoRequiredData)?
        });
      Ok(encoded_collab)
    })
  }

  fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    path: String,
  ) -> FutureResult<(), FlowyError> {
    let database_manager = self.0.clone();
    FutureResult::new(async move {
      database_manager
        .import_csv_from_file(path, CSVFormat::META)
        .await?;
      Ok(())
    })
  }

  fn did_update_view(&self, old: &View, new: &View) -> FutureResult<(), FlowyError> {
    let database_layout = match new.layout {
      ViewLayout::Document | ViewLayout::Chat => {
        return FutureResult::new(async {
          Err(FlowyError::internal().with_context("Can't handle document layout type"))
        });
      },
      ViewLayout::Grid => DatabaseLayoutPB::Grid,
      ViewLayout::Board => DatabaseLayoutPB::Board,
      ViewLayout::Calendar => DatabaseLayoutPB::Calendar,
    };

    let database_manager = self.0.clone();
    let view_id = new.id.clone();
    if old.layout != new.layout {
      FutureResult::new(async move {
        database_manager
          .update_database_layout(&view_id, database_layout)
          .await?;
        Ok(())
      })
    } else {
      FutureResult::new(async move { Ok(()) })
    }
  }
}

#[derive(Debug, serde::Deserialize)]
struct CreateDatabaseExtParams {
  database_id: String,
}

impl CreateDatabaseExtParams {
  pub fn from_map(map: HashMap<String, String>) -> Option<Self> {
    let value = serde_json::to_value(map).ok()?;
    serde_json::from_value::<Self>(value).ok()
  }
}

struct ChatFolderOperation(Arc<ChatManager>);
impl FolderOperationHandler for ChatFolderOperation {
  fn open_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.open_chat(&view_id).await?;
      Ok(())
    })
  }

  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.close_chat(&view_id).await?;
      Ok(())
    })
  }

  fn delete_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.delete_chat(&view_id).await?;
      Ok(())
    })
  }

  fn duplicate_view(&self, _view_id: &str) -> FutureResult<ViewData, FlowyError> {
    FutureResult::new(async move { Err(FlowyError::not_support()) })
  }

  fn create_view_with_view_data(
    &self,
    _user_id: i64,
    _params: CreateViewParams,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move { Err(FlowyError::not_support()) })
  }

  fn create_built_in_view(
    &self,
    user_id: i64,
    view_id: &str,
    _name: &str,
    _layout: ViewLayout,
  ) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.create_chat(&user_id, &view_id).await?;
      Ok(())
    })
  }

  fn import_from_bytes(
    &self,
    _uid: i64,
    _view_id: &str,
    _name: &str,
    _import_type: ImportType,
    _bytes: Vec<u8>,
  ) -> FutureResult<EncodedCollab, FlowyError> {
    FutureResult::new(async move { Err(FlowyError::not_support()) })
  }

  fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    _path: String,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async move { Err(FlowyError::not_support()) })
  }
}
