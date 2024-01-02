use std::collections::HashMap;
use std::convert::TryFrom;
use std::sync::{Arc, Weak};

use bytes::Bytes;

use flowy_document::DocumentIndexContent;
use tokio::sync::RwLock;

use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_database2::entities::DatabaseLayoutPB;
use flowy_database2::services::share::csv::CSVFormat;
use flowy_database2::template::{make_default_board, make_default_calendar, make_default_grid};
use flowy_database2::DatabaseManager;
use flowy_document::entities::DocumentDataPB;
use flowy_document::manager::DocumentManager;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use flowy_error::FlowyError;
use flowy_folder::entities::ViewLayoutPB;
use flowy_folder::manager::{FolderManager, FolderUser};
use flowy_folder::search::{DocumentIndexContentGetter, FolderIndexStorage};
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{FolderOperationHandler, FolderOperationHandlers, View};
use flowy_folder::ViewLayout;
use flowy_folder_deps::entities::ImportData;
use flowy_folder_deps::folder_builder::{ParentChildViews, WorkspaceViewBuilder};
use flowy_user::manager::UserManager;
use flowy_user::services::data_import::ImportDataSource;

use crate::integrate::server::ServerProvider;
use lib_dispatch::prelude::ToBytes;
use lib_infra::async_trait::async_trait;
use lib_infra::future::FutureResult;

pub struct FolderDepsResolver();
impl FolderDepsResolver {
  pub async fn resolve(
    user_manager: Weak<UserManager>,
    document_manager: &Arc<DocumentManager>,
    database_manager: &Arc<DatabaseManager>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    server_provider: Arc<ServerProvider>,
  ) -> Arc<FolderManager> {
    let user: Arc<dyn FolderUser> = Arc::new(FolderUserImpl {
      user_manager: user_manager.clone(),
      database_manager: Arc::downgrade(database_manager),
    });

    let index_storage = FolderIndexStorageImpl(user_manager.clone());
    let document_index_content_getter = DocumentIndexContentGetterImpl(document_manager.clone());
    let handlers = folder_operation_handlers(document_manager.clone(), database_manager.clone());
    Arc::new(
      FolderManager::new(
        user.clone(),
        collab_builder,
        handlers,
        server_provider.clone(),
        index_storage,
        document_index_content_getter,
      )
      .await
      .unwrap(),
    )
  }
}

fn folder_operation_handlers(
  document_manager: Arc<DocumentManager>,
  database_manager: Arc<DatabaseManager>,
) -> FolderOperationHandlers {
  let mut map: HashMap<ViewLayout, Arc<dyn FolderOperationHandler + Send + Sync>> = HashMap::new();

  let document_folder_operation = Arc::new(DocumentFolderOperation(document_manager));
  map.insert(ViewLayout::Document, document_folder_operation);

  let database_folder_operation = Arc::new(DatabaseFolderOperation(database_manager));
  map.insert(ViewLayout::Board, database_folder_operation.clone());
  map.insert(ViewLayout::Grid, database_folder_operation.clone());
  map.insert(ViewLayout::Calendar, database_folder_operation);
  Arc::new(map)
}

struct FolderUserImpl {
  user_manager: Weak<UserManager>,
  database_manager: Weak<DatabaseManager>,
}

#[async_trait]
impl FolderUser for FolderUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
    self
      .user_manager
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .user_id()
  }

  fn token(&self) -> Result<Option<String>, FlowyError> {
    self
      .user_manager
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .token()
  }

  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError> {
    self
      .user_manager
      .upgrade()
      .ok_or(FlowyError::internal().with_context("Unexpected error: UserSession is None"))?
      .get_collab_db(uid)
  }

  async fn import_appflowy_data_folder(
    &self,
    path: &str,
    container_name: Option<String>,
  ) -> Result<Vec<ParentChildViews>, FlowyError> {
    match (self.user_manager.upgrade(), self.database_manager.upgrade()) {
      (Some(user_manager), Some(data_manager)) => {
        let source = ImportDataSource::AppFlowyDataFolder {
          path: path.to_string(),
          container_name,
        };
        let import_data = user_manager.import_data_from_source(source).await?;
        match import_data {
          ImportData::AppFlowyDataFolder {
            views,
            database_view_ids_by_database_id,
            row_object_ids: _,
            database_object_ids: _,
            document_object_ids: _,
          } => {
            let _uid = self.user_id()?;
            data_manager
              .track_database(database_view_ids_by_database_id)
              .await?;
            Ok(views)
          },
        }
      },
      _ => Err(FlowyError::internal().with_context("Unexpected error: UserSession is None")),
    }
  }
}

struct DocumentFolderOperation(Arc<DocumentManager>);
impl FolderOperationHandler for DocumentFolderOperation {
  fn create_workspace_view(
    &self,
    uid: i64,
    workspace_view_builder: Arc<RwLock<WorkspaceViewBuilder>>,
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
      match manager.delete_document(&view_id) {
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
    view_id: &str,
    _name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    _meta: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayout::Document);
    let view_id = view_id.to_string();
    let manager = self.0.clone();
    FutureResult::new(async move {
      let data = DocumentDataPB::try_from(Bytes::from(data))?;
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
  ) -> FutureResult<(), FlowyError> {
    let view_id = view_id.to_string();
    let manager = self.0.clone();
    FutureResult::new(async move {
      let data = DocumentDataPB::try_from(Bytes::from(bytes))?;
      manager
        .create_document(uid, &view_id, Some(data.into()))
        .await?;
      Ok(())
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
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    meta: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    match CreateDatabaseExtParams::from_map(meta) {
      None => {
        let database_manager = self.0.clone();
        let view_id = view_id.to_string();
        FutureResult::new(async move {
          database_manager
            .create_database_with_database_data(&view_id, data)
            .await?;
          Ok(())
        })
      },
      Some(params) => {
        let database_manager = self.0.clone();
        let layout = layout_type_from_view_layout(layout.into());
        let name = name.to_string();
        let database_view_id = view_id.to_string();

        FutureResult::new(async move {
          database_manager
            .create_linked_view(name, layout.into(), params.database_id, database_view_id)
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
  ) -> FutureResult<(), FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    let format = match import_type {
      ImportType::CSV => CSVFormat::Original,
      ImportType::HistoryDatabase => CSVFormat::META,
      ImportType::RawDatabase => CSVFormat::META,
      _ => CSVFormat::Original,
    };
    FutureResult::new(async move {
      let content =
        String::from_utf8(bytes).map_err(|err| FlowyError::internal().with_context(err))?;
      database_manager
        .import_csv(view_id, content, format)
        .await?;
      Ok(())
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
      ViewLayout::Document => {
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

pub fn layout_type_from_view_layout(layout: ViewLayoutPB) -> DatabaseLayoutPB {
  match layout {
    ViewLayoutPB::Grid => DatabaseLayoutPB::Grid,
    ViewLayoutPB::Board => DatabaseLayoutPB::Board,
    ViewLayoutPB::Calendar => DatabaseLayoutPB::Calendar,
    ViewLayoutPB::Document => DatabaseLayoutPB::Grid,
  }
}

struct FolderIndexStorageImpl(Weak<UserManager>);

impl FolderIndexStorage for FolderIndexStorageImpl {
  fn add_view(&self, id: &str, content: &str) -> Result<(), FlowyError> {
    let manager = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;

    let uid = manager.user_id()?;
    manager.add_view_index(uid, id, content)?;
    Ok(())
  }

  fn update_view(&self, id: &str, content: &str) -> Result<(), FlowyError> {
    let manager = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;

    let uid = manager.user_id()?;
    manager.update_view_index(uid, id, content)?;
    Ok(())
  }

  fn remove_view(&self, ids: &[String]) -> Result<(), FlowyError> {
    let manager = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;

    let uid = manager.user_id()?;
    manager.delete_view_index(uid, ids)?;
    Ok(())
  }

  fn add_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError> {
    let manager = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;

    let uid = manager.user_id()?;
    manager.add_document_index(uid, view_id, page_id, content)?;
    Ok(())
  }

  fn update_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError> {
    let manager = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;

    let uid = manager.user_id()?;
    manager.update_document_index(uid, view_id, page_id, content)?;
    Ok(())
  }

  fn remove_document(&self, page_ids: &[String]) -> Result<(), FlowyError> {
    let manager = self
      .0
      .upgrade()
      .ok_or(FlowyError::internal().with_context("The user session is already drop"))?;

    let uid = manager.user_id()?;
    manager.delete_view_index(uid, page_ids)?;
    Ok(())
  }
}

struct DocumentIndexContentGetterImpl(Arc<DocumentManager>);

#[async_trait]
impl DocumentIndexContentGetter for DocumentIndexContentGetterImpl {
  async fn get_document_index_content(
    &self,
    doc_id: &str,
  ) -> Result<DocumentIndexContent, FlowyError> {
    let doc = self.0.get_document(doc_id).await?;
    let index_data = DocumentIndexContent::from(&*doc);
    Ok(index_data)
  }
}
