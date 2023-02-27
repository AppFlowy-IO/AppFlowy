use crate::entities::LayoutTypePB;
use crate::services::database::{
  make_database_block_rev_manager, DatabaseEditor, DatabaseRefIndexerQuery,
  DatabaseRevisionCloudService, DatabaseRevisionMergeable, DatabaseRevisionSerde,
};
use crate::services::database_view::{
  make_database_view_rev_manager, make_database_view_revision_pad, DatabaseViewEditor,
};
use crate::services::persistence::block_index::BlockRowIndexer;
use crate::services::persistence::database_ref::{DatabaseInfo, DatabaseRef, DatabaseRefIndexer};
use crate::services::persistence::kv::DatabaseKVPersistence;
use crate::services::persistence::migration::DatabaseMigration;
use crate::services::persistence::rev_sqlite::{
  SQLiteDatabaseRevisionPersistence, SQLiteDatabaseRevisionSnapshotPersistence,
};
use crate::services::persistence::DatabaseDBConnection;
use std::collections::HashMap;

use database_model::{
  gen_database_id, BuildDatabaseContext, DatabaseRevision, DatabaseViewRevision,
};
use flowy_client_sync::client_database::{
  make_database_block_operations, make_database_operations, make_database_view_operations,
};
use flowy_error::{FlowyError, FlowyResult};
use flowy_revision::{
  RevisionManager, RevisionPersistence, RevisionPersistenceConfiguration, RevisionWebSocket,
};
use flowy_sqlite::ConnectionPool;
use flowy_task::TaskDispatcher;

use revision_model::Revision;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DatabaseUser: Send + Sync {
  fn user_id(&self) -> Result<String, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>;
  fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct DatabaseManager {
  database_editors: RwLock<HashMap<String, Arc<DatabaseEditor>>>,
  database_user: Arc<dyn DatabaseUser>,
  block_indexer: Arc<BlockRowIndexer>,
  database_ref_indexer: Arc<DatabaseRefIndexer>,
  #[allow(dead_code)]
  kv_persistence: Arc<DatabaseKVPersistence>,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  #[allow(dead_code)]
  migration: DatabaseMigration,
}

impl DatabaseManager {
  pub fn new(
    database_user: Arc<dyn DatabaseUser>,
    _rev_web_socket: Arc<dyn RevisionWebSocket>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    database_db: Arc<dyn DatabaseDBConnection>,
  ) -> Self {
    let database_editors = RwLock::new(HashMap::new());
    let kv_persistence = Arc::new(DatabaseKVPersistence::new(database_db.clone()));
    let block_indexer = Arc::new(BlockRowIndexer::new(database_db.clone()));
    let database_ref_indexer = Arc::new(DatabaseRefIndexer::new(database_db.clone()));
    let migration = DatabaseMigration::new(
      database_user.clone(),
      database_db,
      database_ref_indexer.clone(),
    );
    Self {
      database_editors,
      database_user,
      kv_persistence,
      block_indexer,
      database_ref_indexer,
      task_scheduler,
      migration,
    }
  }

  pub async fn initialize_with_new_user(&self, user_id: &str, _token: &str) -> FlowyResult<()> {
    self.migration.run(user_id).await?;
    Ok(())
  }

  pub async fn initialize(&self, user_id: &str, _token: &str) -> FlowyResult<()> {
    self.migration.run(user_id).await?;
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip_all, err)]
  pub async fn create_database<T: AsRef<str>>(
    &self,
    database_id: &str,
    view_id: T,
    name: &str,
    revisions: Vec<Revision>,
  ) -> FlowyResult<()> {
    let db_pool = self.database_user.db_pool()?;
    let _ = self
      .database_ref_indexer
      .bind(database_id, view_id.as_ref(), true, name);
    let rev_manager = self.make_database_rev_manager(database_id, db_pool)?;
    rev_manager.reset_object(revisions).await?;

    Ok(())
  }

  #[tracing::instrument(level = "debug", skip_all, err)]
  async fn create_database_view<T: AsRef<str>>(
    &self,
    view_id: T,
    revisions: Vec<Revision>,
  ) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let rev_manager = make_database_view_rev_manager(&self.database_user, view_id).await?;
    rev_manager.reset_object(revisions).await?;
    Ok(())
  }

  #[tracing::instrument(level = "debug", skip_all, err)]
  pub async fn create_database_block<T: AsRef<str>>(
    &self,
    block_id: T,
    revisions: Vec<Revision>,
  ) -> FlowyResult<()> {
    let block_id = block_id.as_ref();
    let rev_manager = make_database_block_rev_manager(&self.database_user, block_id)?;
    rev_manager.reset_object(revisions).await?;
    Ok(())
  }

  pub async fn open_database_view<T: AsRef<str>>(
    &self,
    view_id: T,
  ) -> FlowyResult<Arc<DatabaseEditor>> {
    let view_id = view_id.as_ref();
    let database_info = self.database_ref_indexer.get_database_with_view(view_id)?;
    self
      .get_or_create_database_editor(&database_info.database_id, view_id)
      .await
  }

  #[tracing::instrument(level = "debug", skip_all, fields(view_id), err)]
  pub async fn close_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let database_info = self.database_ref_indexer.get_database_with_view(view_id)?;
    tracing::Span::current().record("database_id", &database_info.database_id);

    let mut should_remove_editor = false;
    if let Some(database_editor) = self
      .database_editors
      .write()
      .await
      .get(&database_info.database_id)
    {
      database_editor.close_view_editor(view_id).await;
      should_remove_editor = database_editor.number_of_ref_views().await == 0;
      if should_remove_editor {
        database_editor.dispose().await;
      }
    }

    if should_remove_editor {
      self
        .database_editors
        .write()
        .await
        .remove(&database_info.database_id);
    }
    Ok(())
  }

  // #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn get_database_editor(&self, view_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let read_guard = self.database_editors.read().await;
    let editor = read_guard.get(view_id);
    match editor {
      None => {
        // Drop the read_guard ASAP in case of the following read/write lock
        drop(read_guard);
        self.open_database_view(view_id).await
      },
      Some(editor) => Ok(editor.clone()),
    }
  }

  pub async fn get_databases(&self) -> FlowyResult<Vec<DatabaseInfo>> {
    self.database_ref_indexer.get_all_databases()
  }

  pub async fn get_database_ref_views(&self, database_id: &str) -> FlowyResult<Vec<DatabaseRef>> {
    self
      .database_ref_indexer
      .get_ref_views_with_database(database_id)
  }

  async fn get_or_create_database_editor(
    &self,
    database_id: &str,
    view_id: &str,
  ) -> FlowyResult<Arc<DatabaseEditor>> {
    if let Some(database_editor) = self.database_editors.read().await.get(database_id) {
      let user_id = self.database_user.user_id()?;
      let (view_pad, view_rev_manager) =
        make_database_view_revision_pad(view_id, self.database_user.clone()).await?;

      let view_editor = DatabaseViewEditor::from_pad(
        &user_id,
        database_editor.database_view_data.clone(),
        database_editor.cell_data_cache.clone(),
        view_rev_manager,
        view_pad,
      )
      .await?;
      database_editor.open_view_editor(view_editor).await;
      return Ok(database_editor.clone());
    }
    // Lock the database_editors
    let mut database_editors = self.database_editors.write().await;
    let db_pool = self.database_user.db_pool()?;
    let editor = self.make_database_rev_editor(view_id, db_pool).await?;
    database_editors.insert(database_id.to_string(), editor.clone());
    Ok(editor)
  }

  #[tracing::instrument(level = "trace", skip(self, pool), err)]
  async fn make_database_rev_editor(
    &self,
    view_id: &str,
    pool: Arc<ConnectionPool>,
  ) -> Result<Arc<DatabaseEditor>, FlowyError> {
    let user = self.database_user.clone();
    tracing::debug!("Open database view: {}", view_id);
    let (base_view_pad, base_view_rev_manager) =
      make_database_view_revision_pad(view_id, user.clone()).await?;
    let mut database_id = base_view_pad.database_id.clone();

    tracing::debug!("Open database:{}", database_id);
    if database_id.is_empty() {
      // Before the database_id concept comes up, we used the view_id directly. So if
      // the database_id is empty, which means we can used the view_id. After the version 0.1.1,
      // we start to used the database_id that enables binding different views to the same database.
      database_id = view_id.to_owned();
    }

    let token = user.token()?;
    let cloud = Arc::new(DatabaseRevisionCloudService::new(token));
    let mut rev_manager = self.make_database_rev_manager(&database_id, pool.clone())?;
    let database_pad = Arc::new(RwLock::new(
      rev_manager
        .initialize::<DatabaseRevisionSerde>(Some(cloud))
        .await?,
    ));
    let user_id = user.user_id()?;
    let database_editor = DatabaseEditor::new(
      &database_id,
      user,
      database_pad,
      rev_manager,
      self.block_indexer.clone(),
      self.database_ref_indexer.clone(),
      self.task_scheduler.clone(),
    )
    .await?;

    let base_view_editor = DatabaseViewEditor::from_pad(
      &user_id,
      database_editor.database_view_data.clone(),
      database_editor.cell_data_cache.clone(),
      base_view_rev_manager,
      base_view_pad,
    )
    .await?;
    database_editor.open_view_editor(base_view_editor).await;

    Ok(database_editor)
  }

  #[tracing::instrument(level = "trace", skip(self, pool), err)]
  pub fn make_database_rev_manager(
    &self,
    database_id: &str,
    pool: Arc<ConnectionPool>,
  ) -> FlowyResult<RevisionManager<Arc<ConnectionPool>>> {
    let user_id = self.database_user.user_id()?;

    // Create revision persistence
    let disk_cache = SQLiteDatabaseRevisionPersistence::new(&user_id, pool.clone());
    let configuration = RevisionPersistenceConfiguration::new(6, false);
    let rev_persistence =
      RevisionPersistence::new(&user_id, database_id, disk_cache, configuration);

    // Create snapshot persistence
    const DATABASE_SP_PREFIX: &str = "grid";
    let snapshot_object_id = format!("{}:{}", DATABASE_SP_PREFIX, database_id);
    let snapshot_persistence =
      SQLiteDatabaseRevisionSnapshotPersistence::new(&snapshot_object_id, pool);

    let rev_compress = DatabaseRevisionMergeable();
    let rev_manager = RevisionManager::new(
      &user_id,
      database_id,
      rev_persistence,
      rev_compress,
      snapshot_persistence,
    );
    Ok(rev_manager)
  }
}

pub async fn link_existing_database(
  view_id: &str,
  name: String,
  database_id: &str,
  layout: LayoutTypePB,
  database_manager: Arc<DatabaseManager>,
) -> FlowyResult<()> {
  tracing::trace!(
    "Link database view: {} with database: {}",
    view_id,
    database_id
  );
  let database_view_rev = DatabaseViewRevision::new(
    database_id.to_string(),
    view_id.to_owned(),
    false,
    name.clone(),
    layout.into(),
  );
  let database_view_ops = make_database_view_operations(&database_view_rev);
  let database_view_bytes = database_view_ops.json_bytes();
  let revision = Revision::initial_revision(view_id, database_view_bytes);
  database_manager
    .create_database_view(view_id, vec![revision])
    .await?;

  let _ = database_manager
    .database_ref_indexer
    .bind(database_id, view_id, false, &name);
  Ok(())
}

pub async fn create_new_database(
  view_id: &str,
  name: String,
  layout: LayoutTypePB,
  database_manager: Arc<DatabaseManager>,
  build_context: BuildDatabaseContext,
) -> FlowyResult<()> {
  let BuildDatabaseContext {
    field_revs,
    block_metas,
    blocks,
    database_view_data,
  } = build_context;

  for block_meta_data in &blocks {
    let block_id = &block_meta_data.block_id;
    // Indexing the block's rows
    block_meta_data.rows.iter().for_each(|row| {
      let _ = database_manager
        .block_indexer
        .insert(&row.block_id, &row.id);
    });

    // Create database's block
    let database_block_ops = make_database_block_operations(block_meta_data);
    let database_block_bytes = database_block_ops.json_bytes();
    let revision = Revision::initial_revision(block_id, database_block_bytes);
    database_manager
      .create_database_block(&block_id, vec![revision])
      .await?;
  }

  let database_id = gen_database_id();
  let database_rev = DatabaseRevision::from_build_context(&database_id, field_revs, block_metas);

  // Create database
  tracing::trace!("Create new database: {}", database_id);
  let database_ops = make_database_operations(&database_rev);
  let database_bytes = database_ops.json_bytes();
  let revision = Revision::initial_revision(&database_id, database_bytes);
  database_manager
    .create_database(&database_id, &view_id, &name, vec![revision])
    .await?;

  // Create database view
  tracing::trace!("Create new database view: {}", view_id);
  let database_view_rev = if database_view_data.is_empty() {
    DatabaseViewRevision::new(database_id, view_id.to_owned(), true, name, layout.into())
  } else {
    DatabaseViewRevision::from_json(database_view_data)?
  };
  let database_view_ops = make_database_view_operations(&database_view_rev);
  let database_view_bytes = database_view_ops.json_bytes();
  let revision = Revision::initial_revision(view_id, database_view_bytes);
  database_manager
    .create_database_view(view_id, vec![revision])
    .await?;

  Ok(())
}

impl DatabaseRefIndexerQuery for DatabaseRefIndexer {
  fn get_ref_views(&self, database_id: &str) -> FlowyResult<Vec<DatabaseRef>> {
    self.get_ref_views_with_database(database_id)
  }
}

impl DatabaseRefIndexerQuery for Arc<DatabaseRefIndexer> {
  fn get_ref_views(&self, database_id: &str) -> FlowyResult<Vec<DatabaseRef>> {
    (**self).get_ref_views(database_id)
  }
}
