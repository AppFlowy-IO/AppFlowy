use anyhow::anyhow;
use std::collections::HashMap;
use std::sync::{Arc, Weak};

use collab::core::collab::{DataSource, MutexCollab};
use collab_database::database::DatabaseData;
use collab_database::error::DatabaseError;
use collab_database::rows::RowId;
use collab_database::views::{CreateDatabaseParams, CreateViewParams, DatabaseLayout};
use collab_database::workspace_database::{
  CollabDocStateByOid, CollabFuture, DatabaseCollabService, DatabaseMeta, WorkspaceDatabase,
};
use collab_entity::CollabType;
use collab_plugins::local_storage::kv::KVTransactionDB;
use tokio::sync::{Mutex, RwLock};
use tracing::{event, instrument, trace};

use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use collab_integrate::{CollabKVAction, CollabKVDB, CollabPersistenceConfig};
use flowy_database_pub::cloud::{DatabaseCloudService, SummaryRowContent};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use lib_infra::box_any::BoxAny;
use lib_infra::priority_task::TaskDispatcher;

use crate::entities::{DatabaseLayoutPB, DatabaseSnapshotPB};
use crate::services::cell::stringify_cell;
use crate::services::database::DatabaseEditor;
use crate::services::database_view::DatabaseLayoutDepsResolver;
use crate::services::field_settings::default_field_settings_by_layout_map;
use crate::services::share::csv::{CSVFormat, CSVImporter, ImportResult};

pub trait DatabaseUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn workspace_database_object_id(&self) -> Result<String, FlowyError>;
}

pub struct DatabaseManager {
  user: Arc<dyn DatabaseUser>,
  workspace_database: Arc<RwLock<Option<Arc<WorkspaceDatabase>>>>,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  editors: Mutex<HashMap<String, Arc<DatabaseEditor>>>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  cloud_service: Arc<dyn DatabaseCloudService>,
}

impl DatabaseManager {
  pub fn new(
    database_user: Arc<dyn DatabaseUser>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
  ) -> Self {
    Self {
      user: database_user,
      workspace_database: Default::default(),
      task_scheduler,
      editors: Default::default(),
      collab_builder,
      cloud_service,
    }
  }

  fn is_collab_exist(&self, uid: i64, collab_db: &Weak<CollabKVDB>, object_id: &str) -> bool {
    match collab_db.upgrade() {
      None => false,
      Some(collab_db) => {
        let read_txn = collab_db.read_txn();
        read_txn.is_exist(uid, object_id)
      },
    }
  }

  /// When initialize with new workspace, all the resources will be cleared.
  pub async fn initialize(&self, uid: i64) -> FlowyResult<()> {
    // 1. Clear all existing tasks
    self.task_scheduler.write().await.clear_task();
    // 2. Release all existing editors
    for (_, editor) in self.editors.lock().await.iter() {
      editor.close_all_views().await;
    }
    self.editors.lock().await.clear();
    // 3. Clear the workspace database
    if let Some(old_workspace_database) = self.workspace_database.write().await.take() {
      old_workspace_database.close();
    }
    *self.workspace_database.write().await = None;

    let collab_db = self.user.collab_db(uid)?;
    let collab_builder = UserDatabaseCollabServiceImpl {
      user: self.user.clone(),
      collab_builder: self.collab_builder.clone(),
      cloud_service: self.cloud_service.clone(),
    };
    let config = CollabPersistenceConfig::new().snapshot_per_update(100);

    let workspace_id = self.user.workspace_id()?;
    let workspace_database_object_id = self.user.workspace_database_object_id()?;
    let mut workspace_database_doc_state = DataSource::Disk;
    // If the workspace database not exist in disk, try to fetch from remote.
    if !self.is_collab_exist(uid, &collab_db, &workspace_database_object_id) {
      trace!("workspace database not exist, try to fetch from remote");
      match self
        .cloud_service
        .get_database_object_doc_state(
          &workspace_database_object_id,
          CollabType::WorkspaceDatabase,
          &workspace_id,
        )
        .await
      {
        Ok(doc_state) => match doc_state {
          Some(doc_state) => {
            workspace_database_doc_state = DataSource::DocStateV1(doc_state);
          },
          None => {
            workspace_database_doc_state = DataSource::Disk;
          },
        },
        Err(err) => {
          return Err(FlowyError::record_not_found().with_context(format!(
            "get workspace database :{} failed: {}",
            workspace_database_object_id, err,
          )));
        },
      }
    }

    // Construct the workspace database.
    event!(
      tracing::Level::INFO,
      "open aggregate database views object: {}",
      &workspace_database_object_id
    );
    let collab = collab_builder.build_collab_with_config(
      uid,
      &workspace_database_object_id,
      CollabType::WorkspaceDatabase,
      collab_db.clone(),
      workspace_database_doc_state,
      config.clone(),
    )?;
    let workspace_database =
      WorkspaceDatabase::open(uid, collab, collab_db, config, collab_builder);
    *self.workspace_database.write().await = Some(Arc::new(workspace_database));
    Ok(())
  }

  #[instrument(
    name = "database_initialize_with_new_user",
    level = "debug",
    skip_all,
    err
  )]
  pub async fn initialize_with_new_user(&self, user_id: i64) -> FlowyResult<()> {
    self.initialize(user_id).await?;
    Ok(())
  }

  pub async fn get_database_inline_view_id(&self, database_id: &str) -> FlowyResult<String> {
    let wdb = self.get_database_indexer().await?;
    let database_collab = wdb.get_database(database_id).await.ok_or_else(|| {
      FlowyError::record_not_found().with_context(format!("The database:{} not found", database_id))
    })?;

    let lock_guard = database_collab.lock();
    Ok(lock_guard.get_inline_view_id())
  }

  pub async fn get_all_databases_meta(&self) -> Vec<DatabaseMeta> {
    let mut items = vec![];
    if let Ok(wdb) = self.get_database_indexer().await {
      items = wdb.get_all_database_meta()
    }
    items
  }

  pub async fn update_database_indexing(
    &self,
    view_ids_by_database_id: HashMap<String, Vec<String>>,
  ) -> FlowyResult<()> {
    let wdb = self.get_database_indexer().await?;
    view_ids_by_database_id
      .into_iter()
      .for_each(|(database_id, view_ids)| {
        wdb.track_database(&database_id, view_ids);
      });
    Ok(())
  }

  pub async fn get_database_with_view_id(&self, view_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let database_id = self.get_database_id_with_view_id(view_id).await?;
    self.get_database(&database_id).await
  }

  pub async fn get_database_id_with_view_id(&self, view_id: &str) -> FlowyResult<String> {
    let wdb = self.get_database_indexer().await?;
    wdb.get_database_id_with_view_id(view_id).ok_or_else(|| {
      FlowyError::record_not_found()
        .with_context(format!("The database for view id: {} not found", view_id))
    })
  }

  pub async fn get_database(&self, database_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    if let Some(editor) = self.editors.lock().await.get(database_id).cloned() {
      return Ok(editor);
    }
    // TODO(nathan): refactor the get_database that split the database creation and database opening.
    self.open_database(database_id).await
  }

  pub async fn open_database(&self, database_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    trace!("open database editor:{}", database_id);
    let database = self
      .get_database_indexer()
      .await?
      .get_database(database_id)
      .await
      .ok_or_else(|| FlowyError::collab_not_sync().with_context("open database error"))?;

    let editor = Arc::new(DatabaseEditor::new(database, self.task_scheduler.clone()).await?);
    self
      .editors
      .lock()
      .await
      .insert(database_id.to_string(), editor.clone());
    Ok(editor)
  }

  pub async fn open_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let wdb = self.get_database_indexer().await?;
    if let Some(database_id) = wdb.get_database_id_with_view_id(view_id) {
      if let Some(database) = wdb.open_database(&database_id) {
        if let Some(lock_database) = database.try_lock() {
          if let Some(lock_collab) = lock_database.get_collab().try_lock() {
            trace!("{} database start init sync", view_id);
            lock_collab.start_init_sync();
          }
        }
      }
    }
    Ok(())
  }

  pub async fn close_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let wdb = self.get_database_indexer().await?;
    let database_id = wdb.get_database_id_with_view_id(view_id);
    if let Some(database_id) = database_id {
      let mut editors = self.editors.lock().await;
      let mut should_remove = false;
      if let Some(editor) = editors.get(&database_id) {
        editor.close_view(view_id).await;
        should_remove = editor.num_views().await == 0;
      }

      if should_remove {
        trace!("remove database editor:{}", database_id);
        editors.remove(&database_id);
        wdb.close_database(&database_id);
      }
    }

    Ok(())
  }

  pub async fn delete_database_view(&self, view_id: &str) -> FlowyResult<()> {
    let database = self.get_database_with_view_id(view_id).await?;
    let _ = database.delete_database_view(view_id).await?;
    Ok(())
  }

  pub async fn duplicate_database(&self, view_id: &str) -> FlowyResult<Vec<u8>> {
    let wdb = self.get_database_indexer().await?;
    let data = wdb.get_database_data(view_id).await?;
    let json_bytes = data.to_json_bytes()?;
    Ok(json_bytes)
  }

  /// Create a new database with the given data that can be deserialized to [DatabaseData].
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn create_database_with_database_data(
    &self,
    view_id: &str,
    data: Vec<u8>,
  ) -> FlowyResult<()> {
    let database_data = DatabaseData::from_json_bytes(data)?;

    let mut create_database_params = CreateDatabaseParams::from_database_data(database_data);
    let old_view_id = create_database_params.inline_view_id.clone();
    create_database_params.inline_view_id = view_id.to_string();

    if let Some(create_view_params) = create_database_params
      .views
      .iter_mut()
      .find(|view| view.view_id == old_view_id)
    {
      create_view_params.view_id = view_id.to_string();
    }

    let wdb = self.get_database_indexer().await?;
    let _ = wdb.create_database(create_database_params)?;
    Ok(())
  }

  pub async fn create_database_with_params(&self, params: CreateDatabaseParams) -> FlowyResult<()> {
    let wdb = self.get_database_indexer().await?;
    let _ = wdb.create_database(params)?;
    Ok(())
  }

  /// A linked view is a view that is linked to existing database.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn create_linked_view(
    &self,
    name: String,
    layout: DatabaseLayout,
    database_id: String,
    database_view_id: String,
  ) -> FlowyResult<()> {
    let wdb = self.get_database_indexer().await?;
    let mut params = CreateViewParams::new(database_id.clone(), database_view_id, name, layout);
    if let Some(database) = wdb.get_database(&database_id).await {
      let (field, layout_setting) = DatabaseLayoutDepsResolver::new(database, layout)
        .resolve_deps_when_create_database_linked_view();
      if let Some(field) = field {
        params = params.with_deps_fields(vec![field], vec![default_field_settings_by_layout_map()]);
      }
      if let Some(layout_setting) = layout_setting {
        params = params.with_layout_setting(layout_setting);
      }
    };
    wdb.create_database_linked_view(params).await?;
    Ok(())
  }

  pub async fn import_csv(
    &self,
    view_id: String,
    content: String,
    format: CSVFormat,
  ) -> FlowyResult<ImportResult> {
    let params = tokio::task::spawn_blocking(move || {
      CSVImporter.import_csv_from_string(view_id, content, format)
    })
    .await
    .map_err(internal_error)??;
    let result = ImportResult {
      database_id: params.database_id.clone(),
      view_id: params.inline_view_id.clone(),
    };
    self.create_database_with_params(params).await?;
    Ok(result)
  }

  // will implement soon
  pub async fn import_csv_from_file(
    &self,
    _file_path: String,
    _format: CSVFormat,
  ) -> FlowyResult<()> {
    Ok(())
  }

  pub async fn export_csv(&self, view_id: &str, style: CSVFormat) -> FlowyResult<String> {
    let database = self.get_database_with_view_id(view_id).await?;
    database.export_csv(style).await
  }

  pub async fn update_database_layout(
    &self,
    view_id: &str,
    layout: DatabaseLayoutPB,
  ) -> FlowyResult<()> {
    let database = self.get_database_with_view_id(view_id).await?;
    database.update_view_layout(view_id, layout.into()).await
  }

  pub async fn get_database_snapshots(
    &self,
    view_id: &str,
    limit: usize,
  ) -> FlowyResult<Vec<DatabaseSnapshotPB>> {
    let database_id = self.get_database_id_with_view_id(view_id).await?;
    let snapshots = self
      .cloud_service
      .get_database_collab_object_snapshots(&database_id, limit)
      .await?
      .into_iter()
      .map(|snapshot| DatabaseSnapshotPB {
        snapshot_id: snapshot.snapshot_id,
        snapshot_desc: "".to_string(),
        created_at: snapshot.created_at,
        data: snapshot.data,
      })
      .collect::<Vec<_>>();

    Ok(snapshots)
  }

  /// Return the database indexer.
  /// Each workspace has itw own Database indexer that manages all the databases and database views
  async fn get_database_indexer(&self) -> FlowyResult<Arc<WorkspaceDatabase>> {
    let database = self.workspace_database.read().await;
    match &*database {
      None => Err(FlowyError::internal().with_context("Workspace database not initialized")),
      Some(user_database) => Ok(user_database.clone()),
    }
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn summarize_row(
    &self,
    view_id: String,
    row_id: RowId,
    field_id: String,
  ) -> FlowyResult<()> {
    let database = self.get_database_with_view_id(&view_id).await?;

    //
    let mut summary_row_content = SummaryRowContent::new();
    if let Some(row) = database.get_row(&view_id, &row_id) {
      let fields = database.get_fields(&view_id, None);
      for field in fields {
        if let Some(cell) = row.cells.get(&field.id) {
          summary_row_content.insert(field.name.clone(), stringify_cell(cell, &field));
        }
      }
    }

    // Call the cloud service to summarize the row.
    trace!(
      "[AI]: summarize row:{}, content:{:?}",
      row_id,
      summary_row_content
    );
    let response = self
      .cloud_service
      .summary_database_row(&self.user.workspace_id()?, &row_id, summary_row_content)
      .await?;
    trace!("[AI]:summarize row response: {}", response);

    // Update the cell with the response from the cloud service.
    database
      .update_cell_with_changeset(&view_id, &row_id, &field_id, BoxAny::new(response))
      .await?;
    Ok(())
  }

  /// Only expose this method for testing
  #[cfg(debug_assertions)]
  pub fn get_cloud_service(&self) -> &Arc<dyn DatabaseCloudService> {
    &self.cloud_service
  }
}

struct UserDatabaseCollabServiceImpl {
  user: Arc<dyn DatabaseUser>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  cloud_service: Arc<dyn DatabaseCloudService>,
}

impl DatabaseCollabService for UserDatabaseCollabServiceImpl {
  fn get_collab_doc_state(
    &self,
    object_id: &str,
    object_ty: CollabType,
  ) -> CollabFuture<Result<DataSource, DatabaseError>> {
    let workspace_id = self.user.workspace_id().unwrap();
    let object_id = object_id.to_string();
    let weak_cloud_service = Arc::downgrade(&self.cloud_service);
    Box::pin(async move {
      match weak_cloud_service.upgrade() {
        None => Err(DatabaseError::Internal(anyhow!("Cloud service is dropped"))),
        Some(cloud_service) => {
          let doc_state = cloud_service
            .get_database_object_doc_state(&object_id, object_ty, &workspace_id)
            .await?;
          match doc_state {
            None => Ok(DataSource::Disk),
            Some(doc_state) => Ok(DataSource::DocStateV1(doc_state)),
          }
        },
      }
    })
  }

  fn batch_get_collab_update(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> CollabFuture<Result<CollabDocStateByOid, DatabaseError>> {
    let cloned_user = self.user.clone();
    let weak_cloud_service = Arc::downgrade(&self.cloud_service);
    Box::pin(async move {
      let workspace_id = cloned_user
        .workspace_id()
        .map_err(|err| DatabaseError::Internal(err.into()))?;
      match weak_cloud_service.upgrade() {
        None => {
          tracing::warn!("Cloud service is dropped");
          Ok(CollabDocStateByOid::default())
        },
        Some(cloud_service) => {
          let updates = cloud_service
            .batch_get_database_object_doc_state(object_ids, object_ty, &workspace_id)
            .await?;
          Ok(updates)
        },
      }
    })
  }

  fn build_collab_with_config(
    &self,
    uid: i64,
    object_id: &str,
    object_type: CollabType,
    collab_db: Weak<CollabKVDB>,
    collab_raw_data: DataSource,
    _persistence_config: CollabPersistenceConfig,
  ) -> Result<Arc<MutexCollab>, DatabaseError> {
    let workspace_id = self
      .user
      .workspace_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    let collab = self.collab_builder.build_with_config(
      &workspace_id,
      uid,
      object_id,
      object_type.clone(),
      collab_db.clone(),
      collab_raw_data,
      CollabBuilderConfig::default().sync_enable(true),
    )?;
    Ok(collab)
  }
}
