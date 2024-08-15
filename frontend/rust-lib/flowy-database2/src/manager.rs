use anyhow::anyhow;
use arc_swap::ArcSwapOption;
use async_trait::async_trait;
use std::borrow::BorrowMut;
use std::collections::HashMap;
use std::sync::{Arc, Weak};

use collab::core::collab::DataSource;
use collab::preclude::Collab;
use collab_database::database::{Database, DatabaseData};
use collab_database::error::DatabaseError;
use collab_database::rows::RowId;
use collab_database::views::{CreateDatabaseParams, CreateViewParams, DatabaseLayout};
use collab_database::workspace_database::{
  CollabDocStateByOid, DatabaseCollabService, DatabaseMeta, WorkspaceDatabase,
};
use collab_entity::{CollabType, EncodedCollab};
use collab_plugins::local_storage::kv::KVTransactionDB;
use tokio::sync::{Mutex, RwLock};
use tracing::{event, instrument, trace};

use collab_integrate::collab_builder::{
  AppFlowyCollabBuilder, CollabBuilderConfig, KVDBCollabPersistenceImpl,
};
use collab_integrate::{CollabKVAction, CollabKVDB, CollabPersistenceConfig};
use flowy_database_pub::cloud::{
  DatabaseAIService, DatabaseCloudService, SummaryRowContent, TranslateItem, TranslateRowContent,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use lib_infra::box_any::BoxAny;
use lib_infra::priority_task::TaskDispatcher;

use crate::entities::{DatabaseLayoutPB, DatabaseSnapshotPB, FieldType};
use crate::services::cell::stringify_cell;
use crate::services::database::DatabaseEditor;
use crate::services::database_view::DatabaseLayoutDepsResolver;
use crate::services::field::translate_type_option::translate::TranslateTypeOption;

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
  workspace_database: ArcSwapOption<RwLock<WorkspaceDatabase>>,
  task_scheduler: Arc<RwLock<TaskDispatcher>>,
  editors: Mutex<HashMap<String, Arc<DatabaseEditor>>>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  cloud_service: Arc<dyn DatabaseCloudService>,
  ai_service: Arc<dyn DatabaseAIService>,
}

impl DatabaseManager {
  pub fn new(
    database_user: Arc<dyn DatabaseUser>,
    task_scheduler: Arc<RwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
    ai_service: Arc<dyn DatabaseAIService>,
  ) -> Self {
    Self {
      user: database_user,
      workspace_database: Default::default(),
      task_scheduler,
      editors: Default::default(),
      collab_builder,
      cloud_service,
      ai_service,
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
    if let Some(old_workspace_database) = self.workspace_database.swap(None) {
      let wdb = old_workspace_database.read().await;
      wdb.close();
    }

    let collab_db = self.user.collab_db(uid)?;
    let collab_builder = UserDatabaseCollabServiceImpl {
      user: self.user.clone(),
      collab_builder: self.collab_builder.clone(),
      cloud_service: self.cloud_service.clone(),
    };

    let workspace_id = self.user.workspace_id()?;
    let workspace_database_object_id = self.user.workspace_database_object_id()?;
    let mut workspace_database_doc_state =
      KVDBCollabPersistenceImpl::new(collab_db.clone(), uid).into_data_source();
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
          None => {},
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

    let workspace_id = self
      .user
      .workspace_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    let collab_object = self.collab_builder.collab_object(
      &workspace_id,
      uid,
      &workspace_database_object_id,
      CollabType::WorkspaceDatabase,
    )?;
    let workspace_database = self.collab_builder.create_workspace(
      collab_object,
      workspace_database_doc_state,
      collab_db,
      CollabBuilderConfig::default().sync_enable(true),
      collab_builder,
    )?;
    self.workspace_database.store(Some(workspace_database));
    Ok(())
  }

  //FIXME: we need to initialize sync plugin for newly created collabs
  fn initialize_plugins<T>(
    &self,
    uid: i64,
    object_id: &str,
    collab_db: Weak<CollabKVDB>,
    collab_type: CollabType,
    collab: Arc<RwLock<T>>,
  ) -> FlowyResult<Arc<RwLock<T>>>
  where
    T: BorrowMut<Collab> + Send + Sync + 'static,
  {
    //FIXME: unfortunately UserDatabaseCollabService::build_collab_with_config is broken by
    //  design as it assumes that we can split collab building process, which we cannot because:
    //  1. We should not be able to run plugins ie. SyncPlugin over not-fully initialized collab,
    //     and that's what originally build_collab_with_config did.
    //  2. We cannot fully initialize collab from UserDatabaseCollabService, because
    //     WorkspaceDatabase itself requires UserDatabaseCollabService as constructor parameter.
    // Ideally we should never need to initialize plugins that require collab instance as part of
    // that collab construction process itself - it means that we should redesign SyncPlugin to only
    // be fired once a collab is fully initialized.
    let workspace_id = self
      .user
      .workspace_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    let object = self
      .collab_builder
      .collab_object(&workspace_id, uid, &object_id, collab_type)?;
    let collab = self.collab_builder.finalize(
      object,
      CollabBuilderConfig::default().sync_enable(true),
      collab_db,
      collab,
    )?;
    Ok(collab)
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
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
    let database_collab = wdb.get_database(database_id).await.ok_or_else(|| {
      FlowyError::record_not_found().with_context(format!("The database:{} not found", database_id))
    })?;

    let lock_guard = database_collab.read().await;

    Ok(lock_guard.get_inline_view_id())
  }

  pub async fn get_all_databases_meta(&self) -> Vec<DatabaseMeta> {
    let mut items = vec![];
    if let Some(lock) = self.workspace_database.load_full() {
      let wdb = lock.read().await;
      items = wdb.get_all_database_meta()
    }
    items
  }

  pub async fn update_database_indexing(
    &self,
    view_ids_by_database_id: HashMap<String, Vec<String>>,
  ) -> FlowyResult<()> {
    let lock = self.workspace_database()?;
    let mut wdb = lock.write().await;
    view_ids_by_database_id
      .into_iter()
      .for_each(|(database_id, view_ids)| {
        wdb.track_database(&database_id, view_ids);
      });
    Ok(())
  }

  pub async fn get_database_with_view_id(&self, view_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let database_id = self.get_database_id_with_view_id(view_id).await?;
    self.get_database(database_id).await
  }

  pub async fn get_database_id_with_view_id(&self, view_id: &str) -> FlowyResult<String> {
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
    wdb.get_database_id_with_view_id(view_id).ok_or_else(|| {
      FlowyError::record_not_found()
        .with_context(format!("The database for view id: {} not found", view_id))
    })
  }

  pub async fn get_database_row_ids_with_view_id(&self, view_id: &str) -> FlowyResult<Vec<RowId>> {
    let database = self.get_database_with_view_id(view_id).await?;
    Ok(database.get_row_ids().await)
  }

  pub async fn get_database(&self, database_id: String) -> FlowyResult<Arc<DatabaseEditor>> {
    if let Some(editor) = self.editors.lock().await.get(&database_id).cloned() {
      return Ok(editor);
    }
    // TODO(nathan): refactor the get_database that split the database creation and database opening.
    self.open_database(database_id).await
  }

  pub async fn open_database(&self, database_id: String) -> FlowyResult<Arc<DatabaseEditor>> {
    trace!("open database editor:{}", database_id);
    let lock = self.workspace_database()?;
    let database = lock
      .read()
      .await
      .get_database(&database_id)
      .await
      .ok_or_else(|| FlowyError::collab_not_sync().with_context("open database error"))?;

    let editor = Arc::new(DatabaseEditor::new(database, self.task_scheduler.clone()).await?);
    self
      .editors
      .lock()
      .await
      .insert(database_id, editor.clone());
    Ok(editor)
  }

  pub async fn open_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
    if let Some(database_id) = wdb.get_database_id_with_view_id(view_id) {
      if let Some(database) = wdb.open_database(&database_id) {
        let database = database.read().await;
        trace!("{} database start init sync", view_id);
        database.start_init_sync();
      }
    }
    Ok(())
  }

  pub async fn close_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
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
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
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
  ) -> FlowyResult<EncodedCollab> {
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

    let lock = self.workspace_database()?;
    let mut wdb = lock.write().await;
    let database = wdb.create_database(create_database_params)?;
    let encoded_collab = database
      .read()
      .await
      .encode_collab_v1(|collab| CollabType::Database.validate_require_data(collab))?;
    Ok(encoded_collab)
  }

  pub async fn create_database_with_params(
    &self,
    params: CreateDatabaseParams,
  ) -> FlowyResult<Arc<RwLock<Database>>> {
    let lock = self.workspace_database()?;
    let mut wdb = lock.write().await;
    let database = wdb.create_database(params)?;

    Ok(database)
  }

  /// A linked view is a view that is linked to existing database.
  #[tracing::instrument(level = "trace", skip(self), err)]
  pub async fn create_linked_view(
    &self,
    name: String,
    layout: DatabaseLayout,
    database_id: String,
    database_view_id: String,
    database_parent_view_id: String,
  ) -> FlowyResult<()> {
    let lock = self.workspace_database()?;
    let mut wdb = lock.write().await;
    let mut params = CreateViewParams::new(database_id.clone(), database_view_id, name, layout);
    if let Some(database) = wdb.get_database(&database_id).await {
      let (field, layout_setting, field_settings_map) =
        DatabaseLayoutDepsResolver::new(database, layout)
          .resolve_deps_when_create_database_linked_view(&database_parent_view_id)
          .await;
      if let Some(field) = field {
        params = params.with_deps_fields(vec![field], vec![default_field_settings_by_layout_map()]);
      }
      if let Some(layout_setting) = layout_setting {
        params = params.with_layout_setting(layout_setting);
      }
      if let Some(field_settings_map) = field_settings_map {
        params = params.with_field_settings_map(field_settings_map);
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

    // Currently, we only support importing up to 500 rows. We can support more rows in the future.
    if !cfg!(debug_assertions) && params.rows.len() > 500 {
      return Err(FlowyError::internal().with_context("The number of rows exceeds the limit"));
    }

    let view_id = params.inline_view_id.clone();
    let database_id = params.database_id.clone();
    let database = self.create_database_with_params(params).await?;
    let encoded_collab = database
      .read()
      .await
      .encode_collab_v1(|collab| CollabType::Database.validate_require_data(collab))?;
    let result = ImportResult {
      database_id,
      view_id,
      encoded_collab,
    };
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

  fn workspace_database(&self) -> FlowyResult<Arc<RwLock<WorkspaceDatabase>>> {
    Ok(
      self
        .workspace_database
        .load_full()
        .ok_or_else(|| FlowyError::internal().with_context("Workspace database not initialized"))?,
    )
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn summarize_row(
    &self,
    view_id: String,
    row_id: RowId,
    field_id: String,
  ) -> FlowyResult<()> {
    let database = self.get_database_with_view_id(&view_id).await?;
    let mut summary_row_content = SummaryRowContent::new();
    if let Some(row) = database.get_row(&view_id, &row_id).await {
      let fields = database.get_fields(&view_id, None).await;
      for field in fields {
        // When summarizing a row, skip the content in the "AI summary" cell; it does not need to
        // be summarized.
        if field.id != field_id {
          if FieldType::from(field.field_type).is_ai_field() {
            continue;
          }
          if let Some(cell) = row.cells.get(&field.id) {
            summary_row_content.insert(field.name.clone(), stringify_cell(cell, &field));
          }
        }
      }
    }

    // Call the cloud service to summarize the row.
    trace!(
      "[AI]:summarize row:{}, content:{:?}",
      row_id,
      summary_row_content
    );
    let response = self
      .ai_service
      .summary_database_row(&self.user.workspace_id()?, &row_id, summary_row_content)
      .await?;
    trace!("[AI]:summarize row response: {}", response);

    // Update the cell with the response from the cloud service.
    database
      .update_cell_with_changeset(&view_id, &row_id, &field_id, BoxAny::new(response))
      .await?;
    Ok(())
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn translate_row(
    &self,
    view_id: String,
    row_id: RowId,
    field_id: String,
  ) -> FlowyResult<()> {
    let database = self.get_database_with_view_id(&view_id).await?;
    let mut translate_row_content = TranslateRowContent::new();
    let mut language = "english".to_string();

    if let Some(row) = database.get_row(&view_id, &row_id).await {
      let fields = database.get_fields(&view_id, None).await;
      for field in fields {
        // When translate a row, skip the content in the "AI Translate" cell; it does not need to
        // be translated.
        if field.id != field_id {
          if FieldType::from(field.field_type).is_ai_field() {
            continue;
          }

          if let Some(cell) = row.cells.get(&field.id) {
            translate_row_content.push(TranslateItem {
              title: field.name.clone(),
              content: stringify_cell(cell, &field),
            })
          }
        } else {
          language = TranslateTypeOption::language_from_type(
            field
              .type_options
              .get(&FieldType::Translate.to_string())
              .cloned()
              .map(TranslateTypeOption::from)
              .unwrap_or_default()
              .language_type,
          )
          .to_string();
        }
      }
    }

    // Call the cloud service to summarize the row.
    trace!(
      "[AI]:translate to {}, content:{:?}",
      language,
      translate_row_content
    );
    let response = self
      .ai_service
      .translate_database_row(&self.user.workspace_id()?, translate_row_content, &language)
      .await?;

    // Format the response items into a single string
    let content = response
      .items
      .into_iter()
      .map(|value| {
        value
          .into_values()
          .map(|v| v.to_string())
          .collect::<Vec<String>>()
          .join(", ")
      })
      .collect::<Vec<String>>()
      .join(",");

    trace!("[AI]:translate row response: {}", content);
    // Update the cell with the response from the cloud service.
    database
      .update_cell_with_changeset(&view_id, &row_id, &field_id, BoxAny::new(content))
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

#[async_trait]
impl DatabaseCollabService for UserDatabaseCollabServiceImpl {
  async fn get_collab_doc_state(
    &self,
    object_id: &str,
    object_ty: CollabType,
  ) -> Result<Option<DataSource>, DatabaseError> {
    let workspace_id = self.user.workspace_id().unwrap();
    let object_id = object_id.to_string();
    let weak_cloud_service = Arc::downgrade(&self.cloud_service);

    match weak_cloud_service.upgrade() {
      None => Err(DatabaseError::Internal(anyhow!("Cloud service is dropped"))),
      Some(cloud_service) => {
        let doc_state = cloud_service
          .get_database_object_doc_state(&object_id, object_ty, &workspace_id)
          .await?;
        match doc_state {
          None => Ok(None),
          Some(doc_state) => Ok(Some(DataSource::DocStateV1(doc_state))),
        }
      },
    }
  }

  async fn batch_get_collab_update(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> Result<CollabDocStateByOid, DatabaseError> {
    let cloned_user = self.user.clone();
    let weak_cloud_service = Arc::downgrade(&self.cloud_service);

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
  }

  ///NOTE: this method doesn't initialize plugins, however it is passed into WorkspaceDatabase,
  /// therefore all Database/DatabaseRow creation methods must initialize plugins thmselves.
  fn build_collab_with_config(
    &self,
    uid: i64,
    object_id: &str,
    object_type: CollabType,
    collab_db: Weak<CollabKVDB>,
    collab_doc_state: DataSource,
    _config: CollabPersistenceConfig,
  ) -> Result<Collab, DatabaseError> {
    let workspace_id = self
      .user
      .workspace_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    let object = self
      .collab_builder
      .collab_object(&workspace_id, uid, object_id, object_type)?;
    let collab = self
      .collab_builder
      .build_collab(&object, &collab_db, collab_doc_state)?;
    Ok(collab)
  }
}
