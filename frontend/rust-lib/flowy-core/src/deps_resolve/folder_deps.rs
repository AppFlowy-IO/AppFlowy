use bytes::Bytes;

use collab_entity::{CollabType, EncodedCollab};
use collab_folder::hierarchy_builder::NestedViewBuilder;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use collab_integrate::CollabKVDB;
use flowy_ai::ai_manager::AIManager;
use flowy_database2::entities::DatabaseLayoutPB;
use flowy_database2::services::share::csv::CSVFormat;
use flowy_database2::template::{make_default_board, make_default_calendar, make_default_grid};
use flowy_database2::DatabaseManager;
use flowy_document::entities::DocumentDataPB;
use flowy_document::manager::DocumentManager;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use flowy_error::{FlowyError, FlowyResult};
use flowy_folder::entities::{CreateViewParams, ViewLayoutPB};
use flowy_folder::manager::{FolderManager, FolderUser};
use flowy_folder::share::ImportType;
use flowy_folder::view_operation::{
  DatabaseEncodedCollab, DocumentEncodedCollab, EncodedCollabWrapper, FolderOperationHandler,
  FolderOperationHandlers, ImportedData, View, ViewData,
};
use flowy_folder::ViewLayout;
use flowy_search::folder::indexer::FolderIndexManagerImpl;
use flowy_sqlite::kv::KVStorePreferences;
use flowy_user::services::authenticate_user::AuthenticateUser;
use flowy_user::services::data_import::{load_collab_by_object_id, load_collab_by_object_ids};
use lib_dispatch::prelude::ToBytes;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::sync::{Arc, Weak};
use tokio::sync::RwLock;

use crate::integrate::server::ServerProvider;

use collab_plugins::local_storage::kv::KVTransactionDB;
use lib_infra::async_trait::async_trait;

pub struct FolderDepsResolver();
#[allow(clippy::too_many_arguments)]
impl FolderDepsResolver {
  pub async fn resolve(
    authenticate_user: Weak<AuthenticateUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    server_provider: Arc<ServerProvider>,
    folder_indexer: Arc<FolderIndexManagerImpl>,
    store_preferences: Arc<KVStorePreferences>,
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
  chat_manager: Arc<AIManager>,
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

  fn is_folder_exist_on_disk(&self, uid: i64, workspace_id: &str) -> FlowyResult<bool> {
    self.upgrade_user()?.is_collab_on_disk(uid, workspace_id)
  }
}

struct DocumentFolderOperation(Arc<DocumentManager>);
#[async_trait]
impl FolderOperationHandler for DocumentFolderOperation {
  async fn create_workspace_view(
    &self,
    uid: i64,
    workspace_view_builder: Arc<RwLock<NestedViewBuilder>>,
  ) -> Result<(), FlowyError> {
    let manager = self.0.clone();
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
          .create_document(uid, &view.view.id, Some(document_pb.into()))
          .await
          .unwrap();
        view
      })
      .await;
    Ok(())
  }

  async fn open_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.open_document(view_id).await?;
    Ok(())
  }

  /// Close the document view.
  async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.close_document(view_id).await?;
    Ok(())
  }

  async fn delete_view(&self, view_id: &str) -> Result<(), FlowyError> {
    match self.0.delete_document(view_id).await {
      Ok(_) => tracing::trace!("Delete document: {}", view_id),
      Err(e) => tracing::error!("🔴delete document failed: {}", e),
    }
    Ok(())
  }

  async fn duplicate_view(&self, view_id: &str) -> Result<Bytes, FlowyError> {
    let data: DocumentDataPB = self.0.get_document_data(view_id).await?.into();
    let data_bytes = data.into_bytes().map_err(|_| FlowyError::invalid_data())?;
    Ok(data_bytes)
  }

  async fn create_view_with_view_data(
    &self,
    user_id: i64,
    params: CreateViewParams,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    debug_assert_eq!(params.layout, ViewLayoutPB::Document);
    let data = match params.initial_data {
      ViewData::DuplicateData(data) => Some(DocumentDataPB::try_from(data)?),
      ViewData::Data(data) => Some(DocumentDataPB::try_from(data)?),
      ViewData::Empty => None,
    };
    let encoded_collab = self
      .0
      .create_document(user_id, &params.view_id, data.map(|d| d.into()))
      .await?;
    Ok(Some(encoded_collab))
  }

  async fn get_encoded_collab_v1_from_disk(
    &self,
    user: Arc<dyn FolderUser>,
    view_id: &str,
  ) -> Result<EncodedCollabWrapper, FlowyError> {
    // get the collab_object_id for the document.
    // the collab_object_id for the document is the view_id.

    let uid = user
      .user_id()
      .map_err(|e| e.with_context("unable to get the uid: {}"))?;

    // get the collab db
    let collab_db = user
      .collab_db(uid)
      .map_err(|e| e.with_context("unable to get the collab"))?;
    let collab_db = collab_db.upgrade().ok_or_else(|| {
      FlowyError::internal().with_context(
        "The collab db has been dropped, indicating that the user has switched to a new account",
      )
    })?;
    let collab_read_txn = collab_db.read_txn();

    // read the collab from the db
    let collab = load_collab_by_object_id(uid, &collab_read_txn, view_id).map_err(|e| {
      FlowyError::internal().with_context(format!("load document collab failed: {}", e))
    })?;

    let encoded_collab = collab
        // encode the collab and check the integrity of the collab
        .encode_collab_v1(|collab| CollabType::Document.validate_require_data(collab))
        .map_err(|e| {
          FlowyError::internal().with_context(format!("encode document collab failed: {}", e))
        })?;

    Ok(EncodedCollabWrapper::Document(DocumentEncodedCollab {
      document_encoded_collab: encoded_collab,
    }))
  }

  /// Create a view with built-in data.
  async fn create_view_with_default_data(
    &self,
    user_id: i64,
    view_id: &str,
    _name: &str,
    layout: ViewLayout,
  ) -> Result<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayout::Document);
    match self.0.create_document(user_id, view_id, None).await {
      Ok(_) => Ok(()),
      Err(err) => {
        if err.is_already_exists() {
          Ok(())
        } else {
          Err(err)
        }
      },
    }
  }

  async fn import_from_bytes(
    &self,
    uid: i64,
    view_id: &str,
    _name: &str,
    _import_type: ImportType,
    bytes: Vec<u8>,
  ) -> Result<Vec<ImportedData>, FlowyError> {
    let data = DocumentDataPB::try_from(Bytes::from(bytes))?;
    let encoded_collab = self
      .0
      .create_document(uid, view_id, Some(data.into()))
      .await?;
    Ok(vec![(
      view_id.to_string(),
      CollabType::Document,
      encoded_collab,
    )])
  }

  // will implement soon
  async fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    _path: String,
  ) -> Result<(), FlowyError> {
    Ok(())
  }

  fn name(&self) -> &str {
    "DocumentFolderOperationHandler"
  }
}

struct DatabaseFolderOperation(Arc<DatabaseManager>);

#[async_trait]
impl FolderOperationHandler for DatabaseFolderOperation {
  async fn open_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.open_database_view(view_id).await?;
    Ok(())
  }

  async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.close_database_view(view_id).await?;
    Ok(())
  }

  async fn delete_view(&self, view_id: &str) -> Result<(), FlowyError> {
    match self.0.delete_database_view(view_id).await {
      Ok(_) => tracing::trace!("Delete database view: {}", view_id),
      Err(e) => tracing::error!("🔴delete database failed: {}", e),
    }
    Ok(())
  }

  async fn get_encoded_collab_v1_from_disk(
    &self,
    user: Arc<dyn FolderUser>,
    view_id: &str,
  ) -> Result<EncodedCollabWrapper, FlowyError> {
    // get the collab_object_id for the database.
    //
    // the collab object_id for the database is not the view_id,
    //  we should use the view_id to get the database_id
    let oid = self.0.get_database_id_with_view_id(view_id).await?;
    let row_oids = self.0.get_database_row_ids_with_view_id(view_id).await?;
    let row_metas = self
      .0
      .get_database_row_metas_with_view_id(view_id, row_oids.clone())
      .await?;
    let row_document_ids = row_metas
      .iter()
      .filter_map(|meta| meta.document_id.clone())
      .collect::<Vec<_>>();
    let row_oids = row_oids
      .into_iter()
      .map(|oid| oid.into_inner())
      .collect::<Vec<_>>();
    let database_metas = self.0.get_all_databases_meta().await;

    let uid = user
      .user_id()
      .map_err(|e| e.with_context("unable to get the uid: {}"))?;

    // get the collab db
    let collab_db = user
      .collab_db(uid)
      .map_err(|e| e.with_context("unable to get the collab"))?;
    let collab_db = collab_db.upgrade().ok_or_else(|| {
      FlowyError::internal().with_context(
        "The collab db has been dropped, indicating that the user has switched to a new account",
      )
    })?;

    tokio::task::spawn_blocking(move || {
      let collab_read_txn = collab_db.read_txn();

      let database_collab = load_collab_by_object_id(uid, &collab_read_txn, &oid).map_err(|e| {
        FlowyError::internal().with_context(format!("load database collab failed: {}", e))
      })?;

      let database_encoded_collab = database_collab
          // encode the collab and check the integrity of the collab
          .encode_collab_v1(|collab| CollabType::Database.validate_require_data(collab))
          .map_err(|e| {
            FlowyError::internal().with_context(format!("encode database collab failed: {}", e))
          })?;

      let database_row_encoded_collabs =
        load_collab_by_object_ids(uid, &collab_read_txn, &row_oids)
          .0
          .into_iter()
          .map(|(oid, collab)| {
            collab
              .encode_collab_v1(|c| CollabType::DatabaseRow.validate_require_data(c))
              .map(|encoded| (oid, encoded))
              .map_err(|e| {
                FlowyError::internal().with_context(format!("Database row collab error: {}", e))
              })
          })
          .collect::<Result<HashMap<_, _>, FlowyError>>()?;

      let database_relations = database_metas
        .into_iter()
        .filter_map(|meta| {
          meta
            .linked_views
            .clone()
            .into_iter()
            .next()
            .map(|lv| (meta.database_id, lv))
        })
        .collect::<HashMap<_, _>>();

      let database_row_document_encoded_collabs =
        load_collab_by_object_ids(uid, &collab_read_txn, &row_document_ids)
          .0
          .into_iter()
          .map(|(oid, collab)| {
            collab
              .encode_collab_v1(|c| CollabType::Document.validate_require_data(c))
              .map(|encoded| (oid, encoded))
              .map_err(|e| {
                FlowyError::internal()
                  .with_context(format!("Database row document collab error: {}", e))
              })
          })
          .collect::<Result<HashMap<_, _>, FlowyError>>()?;

      Ok(EncodedCollabWrapper::Database(DatabaseEncodedCollab {
        database_encoded_collab,
        database_row_encoded_collabs,
        database_row_document_encoded_collabs,
        database_relations,
      }))
    })
    .await?
  }

  async fn duplicate_view(&self, view_id: &str) -> Result<Bytes, FlowyError> {
    Ok(Bytes::from(view_id.to_string()))
  }

  /// Create a database view with duplicated data.
  /// If the ext contains the {"database_id": "xx"}, then it will link
  /// to the existing database.
  async fn create_view_with_view_data(
    &self,
    _user_id: i64,
    params: CreateViewParams,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    match CreateDatabaseExtParams::from_map(params.meta.clone()) {
      None => match params.initial_data {
        ViewData::DuplicateData(data) => {
          let duplicated_view_id =
            String::from_utf8(data.to_vec()).map_err(|_| FlowyError::invalid_data())?;
          let encoded_collab = self
            .0
            .duplicate_database(&duplicated_view_id, &params.view_id)
            .await?;
          Ok(Some(encoded_collab))
        },
        ViewData::Data(data) => {
          let encoded_collab = self
            .0
            .create_database_with_data(&params.view_id, data.to_vec())
            .await?;
          Ok(Some(encoded_collab))
        },
        ViewData::Empty => Ok(None),
      },
      Some(database_params) => {
        let layout = match params.layout {
          ViewLayoutPB::Board => DatabaseLayoutPB::Board,
          ViewLayoutPB::Calendar => DatabaseLayoutPB::Calendar,
          ViewLayoutPB::Grid => DatabaseLayoutPB::Grid,
          ViewLayoutPB::Document | ViewLayoutPB::Chat => {
            return Err(FlowyError::not_support());
          },
        };
        let name = params.name.to_string();
        let database_view_id = params.view_id.to_string();
        let database_parent_view_id = params.parent_view_id.to_string();
        self
          .0
          .create_linked_view(
            name,
            layout.into(),
            database_params.database_id,
            database_view_id,
            database_parent_view_id,
          )
          .await?;
        Ok(None)
      },
    }
  }

  /// Create a database view with build-in data.
  /// If the ext contains the {"database_id": "xx"}, then it will link to
  /// the existing database. The data of the database will be shared within
  /// these references views.
  async fn create_view_with_default_data(
    &self,
    _user_id: i64,
    view_id: &str,
    name: &str,
    layout: ViewLayout,
  ) -> Result<(), FlowyError> {
    let name = name.to_string();
    let data = match layout {
      ViewLayout::Grid => make_default_grid(view_id, &name),
      ViewLayout::Board => make_default_board(view_id, &name),
      ViewLayout::Calendar => make_default_calendar(view_id, &name),
      ViewLayout::Document | ViewLayout::Chat => {
        return Err(
          FlowyError::internal().with_context(format!("Can't handle {:?} layout type", layout)),
        );
      },
    };
    let result = self.0.import_database(data).await;
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
  }

  async fn import_from_bytes(
    &self,
    _uid: i64,
    view_id: &str,
    _name: &str,
    import_type: ImportType,
    bytes: Vec<u8>,
  ) -> Result<Vec<ImportedData>, FlowyError> {
    let format = match import_type {
      ImportType::CSV => CSVFormat::Original,
      ImportType::AFDatabase => CSVFormat::META,
      _ => CSVFormat::Original,
    };
    let content = tokio::task::spawn_blocking(move || {
      String::from_utf8(bytes).map_err(|err| FlowyError::internal().with_context(err))
    })
    .await??;
    let result = self
      .0
      .import_csv(view_id.to_string(), content, format)
      .await?;
    Ok(
      result
        .encoded_collabs
        .into_iter()
        .map(|encoded| {
          (
            encoded.object_id,
            encoded.collab_type,
            encoded.encoded_collab,
          )
        })
        .collect(),
    )
  }

  async fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    path: String,
  ) -> Result<(), FlowyError> {
    self.0.import_csv_from_file(path, CSVFormat::META).await?;
    Ok(())
  }

  async fn did_update_view(&self, old: &View, new: &View) -> Result<(), FlowyError> {
    let database_layout = match new.layout {
      ViewLayout::Document | ViewLayout::Chat => {
        return Err(FlowyError::internal().with_context("Can't handle document layout type"));
      },
      ViewLayout::Grid => DatabaseLayoutPB::Grid,
      ViewLayout::Board => DatabaseLayoutPB::Board,
      ViewLayout::Calendar => DatabaseLayoutPB::Calendar,
    };

    if old.layout != new.layout {
      self
        .0
        .update_database_layout(&new.id, database_layout)
        .await?;
      Ok(())
    } else {
      Ok(())
    }
  }

  fn name(&self) -> &str {
    "DatabaseFolderOperationHandler"
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

struct ChatFolderOperation(Arc<AIManager>);

#[async_trait]
impl FolderOperationHandler for ChatFolderOperation {
  fn name(&self) -> &str {
    "ChatFolderOperationHandler"
  }

  async fn open_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.open_chat(view_id).await
  }

  async fn close_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.close_chat(view_id).await
  }

  async fn delete_view(&self, view_id: &str) -> Result<(), FlowyError> {
    self.0.delete_chat(view_id).await
  }

  async fn duplicate_view(&self, _view_id: &str) -> Result<Bytes, FlowyError> {
    Err(FlowyError::not_support())
  }

  async fn create_view_with_view_data(
    &self,
    _user_id: i64,
    _params: CreateViewParams,
  ) -> Result<Option<EncodedCollab>, FlowyError> {
    Err(FlowyError::not_support())
  }

  async fn create_view_with_default_data(
    &self,
    user_id: i64,
    view_id: &str,
    _name: &str,
    _layout: ViewLayout,
  ) -> Result<(), FlowyError> {
    self.0.create_chat(&user_id, view_id).await?;
    Ok(())
  }

  async fn import_from_bytes(
    &self,
    _uid: i64,
    _view_id: &str,
    _name: &str,
    _import_type: ImportType,
    _bytes: Vec<u8>,
  ) -> Result<Vec<ImportedData>, FlowyError> {
    Err(FlowyError::not_support())
  }

  async fn import_from_file_path(
    &self,
    _view_id: &str,
    _name: &str,
    _path: String,
  ) -> Result<(), FlowyError> {
    Err(FlowyError::not_support())
  }
}
