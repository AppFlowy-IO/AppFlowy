use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

use collab_database::database::DuplicatedDatabase;
use collab_database::user::UserDatabase as InnerUserDatabase;
use collab_database::views::{CreateDatabaseParams, CreateViewParams, DatabaseLayout};
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

  pub async fn initialize(&self, user_id: i64, _token: &str) -> FlowyResult<()> {
    let kv = self.user.kv_db()?;
    *self.user_database.lock() = Some(InnerUserDatabase::new(user_id, kv));
    // do nothing
    Ok(())
  }

  pub async fn initialize_with_new_user(&self, user_id: i64, token: &str) -> FlowyResult<()> {
    self.initialize(user_id, token).await?;
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

  #[tracing::instrument(level = "debug", skip_all)]
  pub async fn close_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let database_id = self.with_user_database(None, |database| {
      database.get_database_id_with_view_id(view_id)
    });

    if let Some(database_id) = database_id {
      let mut editors = self.editors.write().await;
      if let Some(editor) = editors.get(&database_id) {
        if editor.close_view_editor(view_id).await {
          editor.close().await;
          editors.remove(&database_id);
        }
      }
    }

    Ok(())
  }

  pub async fn duplicate_database(&self, view_id: &str) -> FlowyResult<Vec<u8>> {
    let database_data = self.with_user_database(Err(FlowyError::internal()), |database| {
      let data = database.get_database_duplicated_data(view_id)?;
      let json_bytes = data.to_json_bytes()?;
      Ok(json_bytes)
    })?;

    Ok(database_data)
  }

  pub async fn create_database_with_duplicated_data(&self, data: Vec<u8>) -> FlowyResult<()> {
    let database_data = DuplicatedDatabase::from_json_bytes(data)?;
    self.with_user_database(
      Err(FlowyError::internal().context("Create database with data failed")),
      |database| {
        let database = database.create_database_with_duplicated_data(database_data)?;
        Ok(database)
      },
    )?;
    Ok(())
  }

  pub async fn create_database_with_params(&self, params: CreateDatabaseParams) -> FlowyResult<()> {
    let _ = self.with_user_database(
      Err(FlowyError::internal().context("Create database with params failed")),
      |user_database| {
        let database = user_database.create_database(params)?;
        Ok(database)
      },
    )?;
    Ok(())
  }

  pub async fn create_linked_view(
    &self,
    name: String,
    layout: DatabaseLayoutPB,
    database_id: String,
    target_view_id: String,
    duplicated_view_id: Option<String>,
  ) -> FlowyResult<()> {
    let view_id = self.with_user_database(
      Err(FlowyError::internal().context("Create database view failed")),
      |user_database| {
        let database = user_database
          .get_database(&database_id)
          .ok_or(FlowyError::record_not_found())?;
        match duplicated_view_id {
          None => {
            let params = CreateViewParams::new(database_id, target_view_id, name, layout.into());
            database.create_linked_view(params);
          },
          Some(duplicated_view_id) => {
            database.duplicate_linked_view(&duplicated_view_id);
          },
        }
        Ok(())
      },
    )?;
    Ok(view_id)
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
