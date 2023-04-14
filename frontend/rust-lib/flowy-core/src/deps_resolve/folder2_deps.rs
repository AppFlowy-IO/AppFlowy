use bytes::Bytes;
use collab_persistence::CollabKV;
use database_model::BuildDatabaseContext;
use flowy_database::entities::DatabaseLayoutPB;
use flowy_database::manager::{create_new_database, link_existing_database, DatabaseManager};
use flowy_database::util::{make_default_board, make_default_calendar, make_default_grid};
use flowy_document::editor::make_transaction_from_document_content;
use flowy_document::DocumentManager;
use flowy_error::FlowyError;

use flowy_database2::DatabaseManager2;
use flowy_folder2::entities::ViewLayoutPB;
use flowy_folder2::manager::{Folder2Manager, FolderUser};
use flowy_folder2::view_ext::{ViewDataProcessor, ViewDataProcessorMap};
use flowy_folder2::ViewLayout;
use flowy_user::services::UserSession;
use lib_infra::future::FutureResult;
use revision_model::Revision;
use std::collections::HashMap;
use std::convert::TryFrom;
use std::sync::Arc;

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

  fn kv_db(&self) -> Result<Arc<CollabKV>, FlowyError> {
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
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    let view_id = view_id.to_string();
    let name = name.to_string();
    let database_manager = self.0.clone();
    match DatabaseExtParams::from_map(ext).map(|params| params.database_id) {
      None => {
        let (build_context, layout) = match layout {
          ViewLayout::Grid => (make_default_grid(), DatabaseLayoutPB::Grid),
          ViewLayout::Board => (make_default_board(), DatabaseLayoutPB::Board),
          ViewLayout::Calendar => (make_default_calendar(), DatabaseLayoutPB::Calendar),
          ViewLayout::Document => {
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
        let layout = layout_type_from_view_layout(layout.into());
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
    _user_id: i64,
    view_id: &str,
    name: &str,
    data: Vec<u8>,
    layout: ViewLayout,
    ext: HashMap<String, String>,
  ) -> FutureResult<(), FlowyError> {
    let view_id = view_id.to_string();
    let database_manager = self.0.clone();
    let layout = layout_type_from_view_layout(layout.into());
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

pub fn layout_type_from_view_layout(layout: ViewLayoutPB) -> DatabaseLayoutPB {
  match layout {
    ViewLayoutPB::Grid => DatabaseLayoutPB::Grid,
    ViewLayoutPB::Board => DatabaseLayoutPB::Board,
    ViewLayoutPB::Calendar => DatabaseLayoutPB::Calendar,
    ViewLayoutPB::Document => DatabaseLayoutPB::Grid,
  }
}
