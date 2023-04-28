use std::collections::HashMap;
use std::sync::Arc;

use bytes::Bytes;
use collab_persistence::kv::rocks_kv::RocksCollabDB;
use flowy_database2::entities::DatabaseLayoutPB;
use flowy_database2::template::{make_default_board, make_default_calendar, make_default_grid};
use flowy_database2::DatabaseManager2;
use flowy_document::editor::make_transaction_from_document_content;
use flowy_document::DocumentManager;
use flowy_error::FlowyError;
use flowy_folder2::entities::ViewLayoutPB;
use flowy_folder2::manager::{Folder2Manager, FolderUser};
use flowy_folder2::view_ext::{ViewDataProcessor, ViewDataProcessorMap};
use flowy_folder2::ViewLayout;
use flowy_user::services::UserSession;
use lib_infra::future::FutureResult;
use revision_model::Revision;

pub struct Folder2DepsResolver();
impl Folder2DepsResolver {
  pub async fn resolve(
    user_session: Arc<UserSession>,
    document_manager: &Arc<DocumentManager>,
    database_manager: &Arc<DatabaseManager2>,
  ) -> Arc<Folder2Manager> {
    let user: Arc<dyn FolderUser> = Arc::new(FolderUserImpl(user_session.clone()));

    let view_data_processor =
      make_view_data_processor(document_manager.clone(), database_manager.clone());
    Arc::new(
      Folder2Manager::new(user.clone(), view_data_processor)
        .await
        .unwrap(),
    )
  }
}

fn make_view_data_processor(
  document_manager: Arc<DocumentManager>,
  database_manager: Arc<DatabaseManager2>,
) -> ViewDataProcessorMap {
  let mut map: HashMap<ViewLayout, Arc<dyn ViewDataProcessor + Send + Sync>> = HashMap::new();

  let document_processor = Arc::new(DocumentViewDataProcessor(document_manager));
  map.insert(ViewLayout::Document, document_processor);

  let database_processor = Arc::new(DatabaseViewDataProcessor(database_manager));
  map.insert(ViewLayout::Board, database_processor.clone());
  map.insert(ViewLayout::Grid, database_processor.clone());
  map.insert(ViewLayout::Calendar, database_processor);
  Arc::new(map)
}

struct FolderUserImpl(Arc<UserSession>);
impl FolderUser for FolderUserImpl {
  fn user_id(&self) -> Result<i64, FlowyError> {
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

  fn kv_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError> {
    self.0.get_kv_db()
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

  fn get_view_data(&self, view_id: &str) -> FutureResult<Bytes, FlowyError> {
    let manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      let editor = manager.open_document_editor(view_id).await?;
      let document_data = Bytes::from(editor.duplicate().await?);
      Ok(document_data)
    })
  }

  fn create_view_with_build_in_data(
    &self,
    _user_id: i64,
    view_id: &str,
    _name: &str,
    layout: ViewLayout,
    _ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayout::Document);
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
    _user_id: i64,
    view_id: &str,
    _name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    _ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    debug_assert_eq!(layout, ViewLayout::Document);
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
}

struct DatabaseViewDataProcessor(Arc<DatabaseManager2>);
impl ViewDataProcessor for DatabaseViewDataProcessor {
  fn close_view(&self, view_id: &str) -> FutureResult<(), FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_string();
    FutureResult::new(async move {
      database_manager.close_database_view(view_id).await?;
      Ok(())
    })
  }

  fn get_view_data(&self, view_id: &str) -> FutureResult<Bytes, FlowyError> {
    let database_manager = self.0.clone();
    let view_id = view_id.to_owned();
    FutureResult::new(async move {
      let delta_bytes = database_manager.duplicate_database(&view_id).await?;
      Ok(Bytes::from(delta_bytes))
    })
  }

  /// Create a database view with build-in data.
  /// If the ext contains the {"database_id": "xx"}, then it will link to
  /// the existing database. The data of the database will be shared within
  /// these references views.
  fn create_view_with_build_in_data(
    &self,
    _user_id: i64,
    view_id: &str,
    name: &str,
    layout: ViewLayout,
    _ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    let name = name.to_string();
    let database_manager = self.0.clone();
    let data = match layout {
      ViewLayout::Grid => make_default_grid(view_id, &name),
      ViewLayout::Board => make_default_board(view_id, &name),
      ViewLayout::Calendar => make_default_calendar(view_id, &name),
      ViewLayout::Document => {
        return FutureResult::new(async move {
          Err(FlowyError::internal().context(format!("Can't handle {:?} layout type", layout)))
        });
      },
    };
    FutureResult::new(async move {
      database_manager.create_database_with_params(data).await?;
      Ok(())
    })
  }

  /// Create a database view with duplicated data.
  /// If the ext contains the {"database_id": "xx"}, then it will link
  /// to the existing database.
  fn create_view_with_custom_data(
    &self,
    _user_id: i64,
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    match CreateDatabaseExtParams::from_map(ext) {
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
        let target_view_id = view_id.to_string();

        FutureResult::new(async move {
          database_manager
            .create_linked_view(
              name,
              layout,
              params.database_id,
              target_view_id,
              params.duplicated_view_id,
            )
            .await?;
          Ok(())
        })
      },
    }
  }
}

#[derive(Debug, serde::Deserialize)]
struct CreateDatabaseExtParams {
  database_id: String,
  duplicated_view_id: Option<String>,
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
