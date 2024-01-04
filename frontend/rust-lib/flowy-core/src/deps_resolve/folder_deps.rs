use std::collections::HashMap;
use std::convert::TryFrom;
use std::sync::{Arc, Weak};

use bytes::Bytes;

use flowy_database2::services::database;
use flowy_folder_deps::cloud::gen_view_id;
use tokio::sync::RwLock;

use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::RocksCollabDB;
use flowy_database2::entities::DatabaseLayoutPB;
use flowy_database2::services::share::csv::CSVFormat;
use flowy_database2::template::{make_default_board, make_default_calendar, make_default_grid};
use flowy_database2::{DatabaseLayout, DatabaseManager};
use flowy_document::entities::DocumentDataPB;
use flowy_document::manager::DocumentManager;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use flowy_error::FlowyError;
use flowy_folder::entities::CreateViewParams;
use flowy_folder::manager::{FolderManager, FolderUser};
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{
  create_view, FolderOperationHandler, FolderOperationHandlers, View,
};
use flowy_folder::ViewLayout;

use flowy_folder_deps::entities::ImportData;
use flowy_folder_deps::folder_builder::{FlattedViews, NestedViewBuilder, ParentChildViews};
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

    let handlers = folder_operation_handlers(document_manager.clone(), database_manager.clone());
    Arc::new(
      FolderManager::new(
        user.clone(),
        collab_builder,
        handlers,
        server_provider.clone(),
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

  fn collab_db(&self, uid: i64) -> Result<Weak<RocksCollabDB>, FlowyError> {
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
            // data_manager
            //   .track_database(database_view_ids_by_database_id)
            //   .await?; YAY
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

  /// Close the document view.
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      manager.close_document(&view_id).await?;
      Ok(())
    })
  }

  fn delete_view(
    &self,
    user_id: i64,
    view_id: &str,
  ) -> FutureResult<Vec<(View, Option<u32>)>, FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      match manager.delete_document(&view_id) {
        Ok(_) => tracing::trace!("Delete document: {}", view_id),
        Err(e) => tracing::error!("🔴delete document failed: {}", e),
      }
      Ok(vec![])
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

  /// Create a document view with passed-in data.
  fn create_view_with_view_data(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> FutureResult<Vec<(View, Option<u32>)>, FlowyError> {
    debug_assert!(params.layout.is_document());
    let view_id = gen_view_id().to_string();
    let manager = self.0.clone();
    FutureResult::new(async move {
      let data = DocumentDataPB::try_from(Bytes::from(params.initial_data.clone()))?;
      let index = params.index.clone();
      manager
        .create_document(user_id, &view_id, Some(data.into()))
        .await?;
      let view = create_view(user_id, view_id, params);
      Ok(vec![(view, index)])
    })
  }

  /// Create a document view with built-in data.
  fn create_built_in_view(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> FutureResult<Vec<(View, Option<u32>)>, FlowyError> {
    debug_assert!(params.layout.is_document());
    let view_id = gen_view_id().to_string();
    let manager = self.0.clone();
    FutureResult::new(async move {
      let result = manager.create_document(user_id, &view_id, None).await;

      match result {
        Ok(_) => {
          let index = params.index.clone();
          let view = create_view(user_id, view_id, params);
          Ok(vec![(view, index)])
        },
        Err(err) if err.is_already_exists() => Ok(vec![]),
        Err(err) => Err(err),
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

  fn delete_view(
    &self,
    user_id: i64,
    view_id: &str,
  ) -> FutureResult<Vec<(View, Option<u32>)>, FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      match database_manager.delete_database_view(&view_id).await {
        Ok(did_create_new_view) => {
          tracing::trace!("Delete database view: {}", view_id);
          if let Some(view) = did_create_new_view {
            let inline_view_id = database_manager
              .get_database_with_view_id(&view.id)
              .await?
              .get_mutex_database()
              .lock()
              .get_inline_view_id();
            let params = CreateViewParams {
              parent_view_id: inline_view_id,
              name: view.name,
              layout: view_layout_from_database_layout(view.layout),
              desc: "".to_string(),
              initial_data: vec![],
              meta: Default::default(),
              set_as_current: true,
              index: None,
            };
            let view = create_view(user_id, view.id, params);
            Ok(vec![(view, None)])
          } else {
            Ok(vec![])
          }
        },
        Err(e) => {
          tracing::error!("🔴delete database failed: {}", e);
          Ok(vec![])
        },
      }
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

  /// Create a database view with passed-in data.
  /// If the ext contains the {"database_id": "xx"}, then it will link
  /// to the existing database.
  fn create_view_with_view_data(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> FutureResult<Vec<(View, Option<u32>)>, FlowyError> {
    debug_assert!(params.layout.is_database());
    let database_manager = self.0.clone();
    match CreateDatabaseExtParams::from_map(params.meta.clone()) {
      None => FutureResult::new(async move {
        let layout = params.layout.clone();
        let database = database_manager
          .create_database_with_database_data(params.initial_data.clone())
          .await?;

        let inline_view_id = database.lock().get_inline_view_id();
        let mut views = database.lock().views.get_all_views();
        let inline_view = views.remove(
          views
            .iter()
            .position(|view| view.id == inline_view_id)
            .unwrap(),
        );
        let linked_view = views.pop().unwrap();

        let mut view_builder = NestedViewBuilder::new(params.parent_view_id.clone(), user_id);
        view_builder
          .with_view_builder(|builder| async {
            builder
              .with_name(params.name.clone())
              .with_layout(layout.clone())
              .with_view_id(inline_view_id.clone())
              .with_child_view_builder(|builder| async {
                builder
                  .with_name(params.name.clone())
                  .with_view_id(linked_view.id.clone())
                  .with_layout(layout.clone())
                  .build()
              })
              .await
              .build()
          })
          .await;
        let views = FlattedViews::flatten_views(view_builder.build())
          .into_iter()
          .map(|view| {
            if view.id == inline_view_id {
              (view, params.index)
            } else {
              (view, None)
            }
          })
          .collect();

        Ok(views)
      }),
      Some(ext_params) => FutureResult::new(async move {
        let view_id = database_manager
          .create_linked_view(
            params.name.clone(),
            database_layout_from_view_layout(params.layout.clone()),
            ext_params.database_id,
          )
          .await?;

        let index = params.index.clone();
        let view = create_view(user_id, view_id, params);
        Ok(vec![(view, index)])
      }),
    }
  }

  /// Create a database view with built-in data.
  fn create_built_in_view(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> FutureResult<Vec<(View, Option<u32>)>, FlowyError> {
    debug_assert!(params.layout.is_database());
    let database_manager = self.0.clone();
    let create_database_params = match params.layout {
      ViewLayout::Grid => make_default_grid(&params.name),
      ViewLayout::Board => make_default_board(&params.name),
      ViewLayout::Calendar => make_default_calendar(&params.name),
      ViewLayout::Document => {
        return FutureResult::new(async move {
          Err(
            FlowyError::internal()
              .with_context(format!("Unexpected layout type {:?}", params.layout)),
          )
        });
      },
    };

    let index = params.index.clone();

    FutureResult::new(async move {
      let result = database_manager
        .create_database_with_params(create_database_params)
        .await;
      match result {
        Ok(database) => {
          let inline_view_id = database.lock().get_inline_view_id();
          let mut views = database.lock().views.get_all_views();
          let _inline_view = views.remove(
            views
              .iter()
              .position(|view| view.id == inline_view_id)
              .unwrap(),
          );
          let linked_view = views.pop().unwrap();

          let mut view_builder = NestedViewBuilder::new(params.parent_view_id.clone(), user_id);
          view_builder
            .with_view_builder(|builder| async {
              builder
                .with_name(&params.name)
                .with_layout(params.layout.clone())
                .with_view_id(inline_view_id.clone())
                .with_child_view_builder(|builder| async {
                  builder
                    .with_name(&params.name)
                    .with_view_id(linked_view.id.clone())
                    .with_layout(params.layout.clone())
                    .build()
                })
                .await
                .build()
            })
            .await;
          let views = FlattedViews::flatten_views(view_builder.build())
            .into_iter()
            .map(|view| {
              if view.id == inline_view_id {
                (view, index)
              } else {
                (view, None)
              }
            })
            .collect();
          Ok(views)
        },
        Err(err) if err.is_already_exists() => Ok(vec![]),
        Err(err) => Err(err),
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

pub fn database_layout_from_view_layout(layout: ViewLayout) -> DatabaseLayout {
  match layout {
    ViewLayout::Grid => DatabaseLayout::Grid,
    ViewLayout::Board => DatabaseLayout::Board,
    ViewLayout::Calendar => DatabaseLayout::Calendar,
    ViewLayout::Document => DatabaseLayout::Grid,
  }
}

pub fn view_layout_from_database_layout(layout: DatabaseLayout) -> ViewLayout {
  match layout {
    DatabaseLayout::Grid => ViewLayout::Grid,
    DatabaseLayout::Board => ViewLayout::Board,
    DatabaseLayout::Calendar => ViewLayout::Calendar,
  }
}
