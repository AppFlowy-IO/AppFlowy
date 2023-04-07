use crate::entities::DatabaseLayoutPB;
use crate::services::database::DatabaseEditor;
use collab_database::user::UserDatabase as InnerUserDatabase;
use collab_persistence::CollabKV;
use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;
use parking_lot::Mutex;
use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DatabaseUser2: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>;
  fn kv_db(&self) -> Result<Arc<CollabKV>, FlowyError>;
}

pub struct DatabaseManager2 {
  user: Arc<dyn DatabaseUser2>,
  user_database: UserDatabase,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  editors: RwLock<HashMap<String, Arc<DatabaseEditor>>>,
}

impl DatabaseManager2 {
  pub fn new(
    database_user: Arc<dyn DatabaseUser2>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
  ) -> FlowyResult<Self> {
    let uid = database_user.user_id()?;
    let kv = database_user.kv_db()?;
    let user_database = UserDatabase::new(uid, kv);
    Ok(Self {
      user: database_user,
      user_database,
      task_scheduler,
      editors: Default::default(),
    })
  }

  pub async fn initialize_with_new_user(&self, _user_id: i64, _token: &str) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn initialize(
    &self,
    _user_id: i64,
    _token: &str,
    _get_views_fn: Fut<Vec<(String, String, DatabaseLayoutPB)>>,
  ) -> FlowyResult<()> {
    // do nothing
    Ok(())
  }

  pub async fn open_database_view(&self, view_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let database_id = self
      .user_database
      .lock()
      .get_database_id_with_view_id(view_id)
      .ok_or(FlowyError::record_not_found())?;

    if let Some(editor) = self.editors.read().await.get(&database_id) {
      return Ok(editor.clone());
    }

    let mut editors = self.editors.write().await;
    let database = self
      .user_database
      .lock()
      .get_database(&database_id)
      .ok_or(FlowyError::record_not_found())?;

    let editor = Arc::new(DatabaseEditor::new(database));
    editors.insert(database_id.to_string(), editor.clone());
    Ok(editor)
  }
}

#[derive(Clone)]
pub struct UserDatabase(Arc<Mutex<InnerUserDatabase>>);

impl UserDatabase {
  fn new(uid: i64, kv: Arc<CollabKV>) -> Self {
    Self(Arc::new(Mutex::new(InnerUserDatabase::new(uid, kv))))
  }
}

impl Deref for UserDatabase {
  type Target = Arc<Mutex<InnerUserDatabase>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

unsafe impl Sync for UserDatabase {}

unsafe impl Send for UserDatabase {}
