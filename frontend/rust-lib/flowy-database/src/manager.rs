use crate::entities::LayoutTypePB;
use crate::services::database::{
  make_database_block_rev_manager, DatabaseEditor, DatabaseRefIndexerQuery,
  DatabaseRevisionCloudService, DatabaseRevisionMergeable, DatabaseRevisionSerde,
};
use crate::services::database_view::{
  make_database_view_rev_manager, make_database_view_revision_pad, DatabaseViewEditor,
};
use crate::services::persistence::block_index::BlockRowIndexer;
use crate::services::persistence::database_ref::{DatabaseInfo, DatabaseRefs, DatabaseViewRef};
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

use lib_infra::future::Fut;
use revision_model::Revision;
use std::sync::Arc;
use tokio::sync::RwLock;

pub trait DatabaseUser: Send + Sync {
  fn user_id(&self) -> Result<String, FlowyError>;
  fn token(&self) -> Result<String, FlowyError>;
  fn db_pool(&self) -> Result<Arc<ConnectionPool>, FlowyError>;
}

pub struct DatabaseManager {
  editors_by_database_id: RwLock<HashMap<String, Arc<DatabaseEditor>>>,
  database_user: Arc<dyn DatabaseUser>,
  block_indexer: Arc<BlockRowIndexer>,
  database_refs: Arc<DatabaseRefs>,
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
    let editors_by_database_id = RwLock::new(HashMap::new());
    let kv_persistence = Arc::new(DatabaseKVPersistence::new(database_db.clone()));
    let block_indexer = Arc::new(BlockRowIndexer::new(database_db.clone()));
    let database_refs = Arc::new(DatabaseRefs::new(database_db));
    let migration = DatabaseMigration::new(database_user.clone(), database_refs.clone());
    Self {
      editors_by_database_id,
      database_user,
      kv_persistence,
      block_indexer,
      database_refs,
      task_scheduler,
      migration,
    }
  }

  pub async fn initialize_with_new_user(&self, _user_id: &str, _token: &str) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn initialize(
    &self,
    user_id: &str,
    _token: &str,
    get_views_fn: Fut<Vec<(String, String, LayoutTypePB)>>,
  ) -> FlowyResult<()> {
    self.migration.run(user_id, get_views_fn).await?;
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
      .database_refs
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
    let user_id = self.database_user.user_id()?;
    let pool = self.database_user.db_pool()?;
    let rev_manager = make_database_view_rev_manager(&user_id, pool, view_id).await?;
    rev_manager.reset_object(revisions).await?;
    Ok(())
  }

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

  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn open_database_view<T: AsRef<str>>(
    &self,
    view_id: T,
  ) -> FlowyResult<Arc<DatabaseEditor>> {
    let view_id = view_id.as_ref();
    let database_info = self.database_refs.get_database_with_view(view_id)?;
    self
      .get_or_create_database_editor(&database_info.database_id, view_id)
      .await
  }

  #[tracing::instrument(level = "debug", skip_all)]
  pub async fn close_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let database_info = self.database_refs.get_database_with_view(view_id)?;
    tracing::Span::current().record("database_id", &database_info.database_id);

    // Create a temporary reference database_editor in case of holding the write lock
    // of editors_by_database_id too long.
    let database_editor = self
      .editors_by_database_id
      .write()
      .await
      .remove(&database_info.database_id);

    if let Some(database_editor) = database_editor {
      database_editor.close_view_editor(view_id).await;
      if database_editor.number_of_ref_views().await == 0 {
        database_editor.dispose().await;
      } else {
        self
          .editors_by_database_id
          .write()
          .await
          .insert(database_info.database_id, database_editor);
      }
    }

    Ok(())
  }

  // #[tracing::instrument(level = "debug", skip(self), err)]
  pub async fn get_database_editor(&self, view_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let database_info = self.database_refs.get_database_with_view(view_id)?;
    let database_editor = self
      .editors_by_database_id
      .read()
      .await
      .get(&database_info.database_id)
      .cloned();
    match database_editor {
      None => {
        // Drop the read_guard ASAP in case of the following read/write lock
        self.open_database_view(view_id).await
      },
      Some(editor) => Ok(editor),
    }
  }

  pub async fn get_databases(&self) -> FlowyResult<Vec<DatabaseInfo>> {
    self.database_refs.get_all_databases()
  }

  pub async fn get_database_ref_views(
    &self,
    database_id: &str,
  ) -> FlowyResult<Vec<DatabaseViewRef>> {
    self.database_refs.get_ref_views_with_database(database_id)
  }

  async fn get_or_create_database_editor(
    &self,
    database_id: &str,
    view_id: &str,
  ) -> FlowyResult<Arc<DatabaseEditor>> {
    let user = self.database_user.clone();
    let create_view_editor = |database_editor: Arc<DatabaseEditor>| async move {
      let user_id = user.user_id()?;
      let (view_pad, view_rev_manager) = make_database_view_revision_pad(view_id, user).await?;
      DatabaseViewEditor::from_pad(
        &user_id,
        database_editor.database_view_data.clone(),
        database_editor.cell_data_cache.clone(),
        view_rev_manager,
        view_pad,
      )
      .await
    };

    let database_editor = self
      .editors_by_database_id
      .read()
      .await
      .get(database_id)
      .cloned();

    match database_editor {
      None => {
        let mut editors_by_database_id = self.editors_by_database_id.write().await;
        let db_pool = self.database_user.db_pool()?;
        let database_editor = self.make_database_rev_editor(view_id, db_pool).await?;
        editors_by_database_id.insert(database_id.to_string(), database_editor.clone());
        Ok(database_editor)
      },
      Some(database_editor) => {
        let is_open = database_editor.is_view_open(view_id).await;
        if !is_open {
          let database_view_editor = create_view_editor(database_editor.clone()).await?;
          database_editor.open_view_editor(database_view_editor).await;
        }

        Ok(database_editor)
      },
    }
  }

  #[tracing::instrument(level = "trace", skip(self, pool), err)]
  async fn make_database_rev_editor(
    &self,
    view_id: &str,
    pool: Arc<ConnectionPool>,
  ) -> Result<Arc<DatabaseEditor>, FlowyError> {
    let user = self.database_user.clone();
    let (base_view_pad, base_view_rev_manager) =
      make_database_view_revision_pad(view_id, user.clone()).await?;
    let mut database_id = base_view_pad.database_id.clone();
    tracing::debug!("Open database: {} with view: {}", database_id, view_id);
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
      self.database_refs.clone(),
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
    .database_refs
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
    layout_setting,
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
  let database_view = if database_view_data.is_empty() {
    let mut database_view =
      DatabaseViewRevision::new(database_id, view_id.to_owned(), true, name, layout.into());
    database_view.layout_settings = layout_setting;
    database_view
  } else {
    let mut database_view = DatabaseViewRevision::from_json(database_view_data)?;
    database_view.database_id = database_id;
    // Replace the view id with the new one. This logic will be removed in the future.
    database_view.view_id = view_id.to_owned();
    database_view
  };

  let database_view_ops = make_database_view_operations(&database_view);
  let database_view_bytes = database_view_ops.json_bytes();
  let revision = Revision::initial_revision(view_id, database_view_bytes);
  database_manager
    .create_database_view(view_id, vec![revision])
    .await?;

  Ok(())
}

impl DatabaseRefIndexerQuery for DatabaseRefs {
  fn get_ref_views(&self, database_id: &str) -> FlowyResult<Vec<DatabaseViewRef>> {
    self.get_ref_views_with_database(database_id)
  }
}

impl DatabaseRefIndexerQuery for Arc<DatabaseRefs> {
  fn get_ref_views(&self, database_id: &str) -> FlowyResult<Vec<DatabaseViewRef>> {
    (**self).get_ref_views(database_id)
  }
}
