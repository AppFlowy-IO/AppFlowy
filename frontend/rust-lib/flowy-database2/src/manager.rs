use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

use collab_database::user::UserDatabase as InnerUserDatabase;
use collab_persistence::CollabKV;
use parking_lot::Mutex;
use tokio::sync::RwLock;

use flowy_error::{FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;
use lib_infra::future::Fut;

use crate::entities::{DatabaseDescriptionPB, DatabaseLayoutPB, RepeatedDatabaseDescriptionPB};
use crate::services::database::{DatabaseEditor, MutexDatabase};

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
  ) -> Self {
    Self {
      user: database_user,
      user_database: UserDatabase::default(),
      task_scheduler,
      editors: Default::default(),
    }
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

  pub async fn initialize_with_new_user(&self, user_id: i64, _token: &str) -> FlowyResult<()> {
    let kv = self.user.kv_db()?;
    *self.user_database.lock() = Some(InnerUserDatabase::new(user_id, kv));
    Ok(())
  }

  pub async fn get_all_databases_description(&self) -> RepeatedDatabaseDescriptionPB {
    let databases_description = self.with_user_database(vec![], |database| {
      database
        .get_all_databases()
        .into_iter()
        .map(DatabaseDescriptionPB::from)
        .collect()
    });

    RepeatedDatabaseDescriptionPB {
      items: databases_description,
    }
  }

  pub async fn get_database(&self, view_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let database_id = self.with_user_database(Err(FlowyError::internal()), |database| {
      database
        .get_database_id_with_view_id(view_id)
        .ok_or(FlowyError::record_not_found())
    })?;

    if let Some(editor) = self.editors.read().await.get(&database_id) {
      return Ok(editor.clone());
    }

    let mut editors = self.editors.write().await;
    let database = MutexDatabase::new(self.with_user_database(
      Err(FlowyError::record_not_found()),
      |database| {
        database
          .get_database(&database_id)
          .ok_or(FlowyError::record_not_found())
      },
    )?);

    let editor = Arc::new(DatabaseEditor::new(database, self.task_scheduler.clone()).await?);
    editors.insert(database_id.to_string(), editor.clone());
    Ok(editor)
  }

  fn with_user_database<F, Output>(&self, default_value: Output, f: F) -> Output
  where
    F: FnOnce(&InnerUserDatabase) -> Output,
  {
    let database = self.user_database.lock();
    match &*database {
      None => default_value,
      Some(folder) => f(folder),
    }
  }
}

#[derive(Clone, Default)]
pub struct UserDatabase(Arc<Mutex<Option<InnerUserDatabase>>>);

impl Deref for UserDatabase {
  type Target = Arc<Mutex<Option<InnerUserDatabase>>>;
  fn deref(&self) -> &Self::Target {
    &self.0
  }
}

unsafe impl Sync for UserDatabase {}

unsafe impl Send for UserDatabase {}
