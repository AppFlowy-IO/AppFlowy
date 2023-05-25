use std::collections::HashMap;
use std::ops::Deref;
use std::sync::Arc;

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::{CollabPersistenceConfig, RocksCollabDB};
use collab::core::collab::MutexCollab;
use collab_database::database::DatabaseData;
use collab_database::user::{UserDatabase as InnerUserDatabase, UserDatabaseCollabBuilder};
use collab_database::views::{CreateDatabaseParams, CreateViewParams};
use parking_lot::Mutex;
use tokio::sync::RwLock;

use flowy_error::{internal_error, FlowyError, FlowyResult};
use flowy_task::TaskDispatcher;

use crate::entities::{DatabaseDescriptionPB, DatabaseLayoutPB, RepeatedDatabaseDescriptionPB};
use crate::services::database::{DatabaseEditor, MutexDatabase};
use crate::services::share::csv::{CSVImporter, ExportStyle};

pub trait DatabaseUser2: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn token(&self) -> Result<Option<String>, FlowyError>;
  fn collab_db(&self) -> Result<Arc<RocksCollabDB>, FlowyError>;
}

pub struct DatabaseManager2 {
  user: Arc<dyn DatabaseUser2>,
  user_database: UserDatabase,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  editors: RwLock<HashMap<String, Arc<DatabaseEditor>>>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
}

impl DatabaseManager2 {
  pub fn new(
    database_user: Arc<dyn DatabaseUser2>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
  ) -> Self {
    Self {
      user: database_user,
      user_database: UserDatabase::default(),
      task_scheduler,
      editors: Default::default(),
      collab_builder,
    }
  }

  pub async fn initialize(&self, user_id: i64) -> FlowyResult<()> {
    let db = self.user.collab_db()?;
    *self.user_database.lock() = Some(InnerUserDatabase::new(
      user_id,
      db,
      CollabPersistenceConfig::default(),
      UserDatabaseCollabBuilderImpl(self.collab_builder.clone()),
    ));
    // do nothing
    Ok(())
  }

  pub async fn initialize_with_new_user(&self, user_id: i64, _token: &str) -> FlowyResult<()> {
    self.initialize(user_id).await?;
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

  pub async fn get_database_with_view_id(&self, view_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let database_id = self.with_user_database(Err(FlowyError::internal()), |database| {
      database
        .get_database_id_with_view_id(view_id)
        .ok_or_else(FlowyError::record_not_found)
    })?;
    self.get_database(&database_id).await
  }

  pub async fn get_database(&self, database_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    if let Some(editor) = self.editors.read().await.get(database_id) {
      return Ok(editor.clone());
    }

    let mut editors = self.editors.write().await;
    let database = MutexDatabase::new(self.with_user_database(
      Err(FlowyError::record_not_found()),
      |database| {
        database
          .get_database(database_id)
          .ok_or_else(FlowyError::record_not_found)
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

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn create_database_with_database_data(
    &self,
    view_id: &str,
    data: Vec<u8>,
  ) -> FlowyResult<()> {
    let mut database_data = DatabaseData::from_json_bytes(data)?;
    database_data.view.id = view_id.to_string();
    self.with_user_database(
      Err(FlowyError::internal().context("Create database with data failed")),
      |database| {
        let database = database.create_database_with_data(database_data)?;
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
    self.with_user_database(
      Err(FlowyError::internal().context("Create database view failed")),
      |user_database| {
        let database = user_database
          .get_database(&database_id)
          .ok_or_else(FlowyError::record_not_found)?;
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
    Ok(())
  }

  pub async fn import_csv(&self, content: String) -> FlowyResult<String> {
    let params = tokio::task::spawn_blocking(move || CSVImporter.import_csv_from_string(content))
      .await
      .map_err(internal_error)??;
    let database_id = params.database_id.clone();
    self.create_database_with_params(params).await?;
    Ok(database_id)
  }

  pub async fn import_csv_data_from_uri(&self, _uri: String) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn export_csv(&self, view_id: &str, style: ExportStyle) -> FlowyResult<String> {
    let database = self.get_database_with_view_id(view_id).await?;
    database.export_csv(style).await
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

struct UserDatabaseCollabBuilderImpl(Arc<AppFlowyCollabBuilder>);

impl UserDatabaseCollabBuilder for UserDatabaseCollabBuilderImpl {
  fn build(&self, uid: i64, object_id: &str, db: Arc<RocksCollabDB>) -> Arc<MutexCollab> {
    self.0.build(uid, object_id, db)
  }

  fn build_with_config(
    &self,
    uid: i64,
    object_id: &str,
    db: Arc<RocksCollabDB>,
    config: &CollabPersistenceConfig,
  ) -> Arc<MutexCollab> {
    self.0.build_with_config(uid, object_id, db, config)
  }
}
