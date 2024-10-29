use anyhow::anyhow;
use arc_swap::ArcSwapOption;
use async_trait::async_trait;
use collab::core::collab::DataSource;
use collab::core::origin::CollabOrigin;
use collab::lock::RwLock;
use collab::preclude::Collab;
use collab_database::database::{Database, DatabaseData};
use collab_database::entity::{CreateDatabaseParams, CreateViewParams};
use collab_database::error::DatabaseError;
use collab_database::rows::RowId;
use collab_database::template::csv::CSVTemplate;
use collab_database::views::DatabaseLayout;
use collab_database::workspace_database::{
  CollabPersistenceImpl, DatabaseCollabPersistenceService, DatabaseCollabService, DatabaseMeta,
  EncodeCollabByOid, WorkspaceDatabaseManager,
};
use collab_entity::{CollabObject, CollabType, EncodedCollab};
use collab_plugins::local_storage::kv::KVTransactionDB;
use rayon::prelude::*;
use std::collections::HashMap;
use std::sync::{Arc, Weak};
use std::time::Duration;
use tokio::sync::Mutex;
use tracing::{error, info, instrument, trace, warn};

use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabBuilderConfig};
use collab_integrate::{CollabKVAction, CollabKVDB};
use flowy_database_pub::cloud::{
  DatabaseAIService, DatabaseCloudService, SummaryRowContent, TranslateItem, TranslateRowContent,
};
use flowy_error::{internal_error, FlowyError, FlowyResult};
use lib_dispatch::prelude::af_spawn;
use lib_infra::box_any::BoxAny;
use lib_infra::priority_task::TaskDispatcher;

use crate::entities::{DatabaseLayoutPB, DatabaseSnapshotPB, FieldType, RowMetaPB};
use crate::services::cell::stringify_cell;
use crate::services::database::DatabaseEditor;
use crate::services::database_view::DatabaseLayoutDepsResolver;
use crate::services::field::translate_type_option::translate::TranslateTypeOption;
use crate::services::field_settings::default_field_settings_by_layout_map;
use crate::services::share::csv::{CSVFormat, CSVImporter, ImportResult};
use tokio::sync::RwLock as TokioRwLock;

pub trait DatabaseUser: Send + Sync {
  fn user_id(&self) -> Result<i64, FlowyError>;
  fn collab_db(&self, uid: i64) -> Result<Weak<CollabKVDB>, FlowyError>;
  fn workspace_id(&self) -> Result<String, FlowyError>;
  fn workspace_database_object_id(&self) -> Result<String, FlowyError>;
}

pub(crate) type DatabaseEditorMap = HashMap<String, Arc<DatabaseEditor>>;
pub struct DatabaseManager {
  user: Arc<dyn DatabaseUser>,
  workspace_database_manager: ArcSwapOption<RwLock<WorkspaceDatabaseManager>>,
  task_scheduler: Arc<TokioRwLock<TaskDispatcher>>,
  pub(crate) editors: Mutex<DatabaseEditorMap>,
  removing_editor: Arc<Mutex<HashMap<String, Arc<DatabaseEditor>>>>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  cloud_service: Arc<dyn DatabaseCloudService>,
  ai_service: Arc<dyn DatabaseAIService>,
}

impl DatabaseManager {
  pub fn new(
    database_user: Arc<dyn DatabaseUser>,
    task_scheduler: Arc<TokioRwLock<TaskDispatcher>>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
    ai_service: Arc<dyn DatabaseAIService>,
  ) -> Self {
    Self {
      user: database_user,
      workspace_database_manager: Default::default(),
      task_scheduler,
      editors: Default::default(),
      removing_editor: Default::default(),
      collab_builder,
      cloud_service,
      ai_service,
    }
  }

  /// When initialize with new workspace, all the resources will be cleared.
  pub async fn initialize(&self, uid: i64, is_local_user: bool) -> FlowyResult<()> {
    // 1. Clear all existing tasks
    self.task_scheduler.write().await.clear_task();
    // 2. Release all existing editors
    for (_, editor) in self.editors.lock().await.iter() {
      editor.close_all_views().await;
    }
    self.editors.lock().await.clear();
    self.removing_editor.lock().await.clear();
    // 3. Clear the workspace database
    if let Some(old_workspace_database) = self.workspace_database_manager.swap(None) {
      info!("Close the old workspace database");
      let wdb = old_workspace_database.read().await;
      wdb.close();
    }

    let collab_db = self.user.collab_db(uid)?;
    let collab_service = WorkspaceDatabaseCollabServiceImpl::new(
      is_local_user,
      self.user.clone(),
      self.collab_builder.clone(),
      self.cloud_service.clone(),
    );

    let workspace_database_object_id = self.user.workspace_database_object_id()?;
    let workspace_database_collab = collab_service
      .build_collab(
        workspace_database_object_id.as_str(),
        CollabType::WorkspaceDatabase,
        None,
      )
      .await?;
    let collab_object = collab_service
      .build_collab_object(&workspace_database_object_id, CollabType::WorkspaceDatabase)?;
    let workspace_database = self.collab_builder.create_workspace_database_manager(
      collab_object,
      workspace_database_collab,
      collab_db,
      CollabBuilderConfig::default().sync_enable(true),
      collab_service,
    )?;

    self
      .workspace_database_manager
      .store(Some(workspace_database));
    Ok(())
  }

  #[instrument(
    name = "database_initialize_with_new_user",
    level = "debug",
    skip_all,
    err
  )]
  pub async fn initialize_with_new_user(
    &self,
    user_id: i64,
    is_local_user: bool,
  ) -> FlowyResult<()> {
    self.initialize(user_id, is_local_user).await?;
    Ok(())
  }

  pub async fn get_database_inline_view_id(&self, database_id: &str) -> FlowyResult<String> {
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
    let database_collab = wdb.get_or_init_database(database_id).await?;
    drop(wdb);
    let lock_guard = database_collab.read().await;
    Ok(lock_guard.get_inline_view_id())
  }

  pub async fn get_all_databases_meta(&self) -> Vec<DatabaseMeta> {
    let mut items = vec![];
    if let Some(lock) = self.workspace_database_manager.load_full() {
      let wdb = lock.read().await;
      items = wdb.get_all_database_meta()
    }
    items
  }

  #[instrument(level = "trace", skip_all, err)]
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

  pub async fn get_database_id_with_view_id(&self, view_id: &str) -> FlowyResult<String> {
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
    let database_id = wdb.get_database_id_with_view_id(view_id);
    database_id.ok_or_else(|| {
      FlowyError::record_not_found()
        .with_context(format!("The database for view id: {} not found", view_id))
    })
  }

  pub async fn get_database_row_ids_with_view_id(&self, view_id: &str) -> FlowyResult<Vec<RowId>> {
    let database = self.get_database_editor_with_view_id(view_id).await?;
    Ok(database.get_row_ids().await)
  }

  pub async fn get_database_row_metas_with_view_id(
    &self,
    view_id: &str,
    row_ids: Vec<RowId>,
  ) -> FlowyResult<Vec<RowMetaPB>> {
    let database = self.get_database_editor_with_view_id(view_id).await?;
    let view_id = view_id.to_string();
    let mut row_metas: Vec<RowMetaPB> = vec![];
    for row_id in row_ids {
      if let Some(row_meta) = database.get_row_meta(&view_id, &row_id).await {
        row_metas.push(row_meta);
      }
    }
    Ok(row_metas)
  }

  pub async fn get_database_editor_with_view_id(
    &self,
    view_id: &str,
  ) -> FlowyResult<Arc<DatabaseEditor>> {
    let database_id = self.get_database_id_with_view_id(view_id).await?;
    self.get_or_init_database_editor(&database_id).await
  }

  pub async fn get_or_init_database_editor(
    &self,
    database_id: &str,
  ) -> FlowyResult<Arc<DatabaseEditor>> {
    if let Some(editor) = self.editors.lock().await.get(database_id).cloned() {
      return Ok(editor);
    }
    let editor = self.open_database(database_id).await?;
    Ok(editor)
  }

  #[instrument(level = "trace", skip_all, err)]
  pub async fn open_database(&self, database_id: &str) -> FlowyResult<Arc<DatabaseEditor>> {
    let workspace_database = self.workspace_database()?;
    if let Some(database_editor) = self.removing_editor.lock().await.remove(database_id) {
      self
        .editors
        .lock()
        .await
        .insert(database_id.to_string(), database_editor.clone());
      return Ok(database_editor);
    }

    trace!("[Database]: init database editor:{}", database_id);
    // When the user opens the database from the left-side bar, it may fail because the workspace database
    // hasn't finished syncing yet. In such cases, get_or_create_database will return None.
    // The workaround is to add a retry mechanism to attempt fetching the database again.
    let database = open_database_with_retry(workspace_database, database_id).await?;
    let editor = DatabaseEditor::new(
      self.user.clone(),
      database,
      self.task_scheduler.clone(),
      self.collab_builder.clone(),
    )
    .await?;

    self
      .editors
      .lock()
      .await
      .insert(database_id.to_string(), editor.clone());
    Ok(editor)
  }

  /// Open the database view
  #[instrument(level = "trace", skip_all, err)]
  pub async fn open_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let lock = self.workspace_database()?;
    let workspace_database = lock.read().await;
    let result = workspace_database.get_database_id_with_view_id(view_id);
    drop(workspace_database);

    if let Some(database_id) = result {
      let is_not_exist = self.editors.lock().await.get(&database_id).is_none();
      if is_not_exist {
        let _ = self.open_database(&database_id).await?;
      }
    }
    Ok(())
  }

  #[instrument(level = "trace", skip_all, err)]
  pub async fn close_database_view<T: AsRef<str>>(&self, view_id: T) -> FlowyResult<()> {
    let view_id = view_id.as_ref();
    let lock = self.workspace_database()?;
    let workspace_database = lock.read().await;
    let database_id = workspace_database.get_database_id_with_view_id(view_id);
    drop(workspace_database);

    if let Some(database_id) = database_id {
      let mut editors = self.editors.lock().await;
      let mut should_remove = false;
      if let Some(editor) = editors.get(&database_id) {
        editor.close_view(view_id).await;
        // when there is no opening views, mark the database to be removed.
        trace!(
          "[Database]: {} has {} opening views",
          database_id,
          editor.num_of_opening_views().await
        );
        should_remove = editor.num_of_opening_views().await == 0;
      }

      if should_remove {
        let editor = editors.remove(&database_id);
        drop(editors);

        if let Some(editor) = editor {
          editor.close_database().await;
          self
            .removing_editor
            .lock()
            .await
            .insert(database_id.to_string(), editor);

          let weak_workspace_database = Arc::downgrade(&self.workspace_database()?);
          let weak_removing_editors = Arc::downgrade(&self.removing_editor);
          af_spawn(async move {
            tokio::time::sleep(std::time::Duration::from_secs(120)).await;
            if let Some(removing_editors) = weak_removing_editors.upgrade() {
              if removing_editors.lock().await.remove(&database_id).is_some() {
                if let Some(workspace_database) = weak_workspace_database.upgrade() {
                  let wdb = workspace_database.write().await;
                  wdb.close_database(&database_id);
                }
              }
            }
          });
        }
      }
    }

    Ok(())
  }

  pub async fn delete_database_view(&self, view_id: &str) -> FlowyResult<()> {
    let database = self.get_database_editor_with_view_id(view_id).await?;
    let _ = database.delete_database_view(view_id).await?;
    Ok(())
  }

  pub async fn get_database_data(&self, view_id: &str) -> FlowyResult<DatabaseData> {
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
    let data = wdb.get_database_data(view_id).await?;
    Ok(data)
  }

  pub async fn get_database_json_string(&self, view_id: &str) -> FlowyResult<String> {
    let lock = self.workspace_database()?;
    let wdb = lock.read().await;
    let data = wdb.get_database_data(view_id).await?;
    let json_string = serde_json::to_string(&data)?;
    Ok(json_string)
  }

  /// Create a new database with the given data that can be deserialized to [DatabaseData].
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn create_database_with_data(
    &self,
    new_database_view_id: &str,
    data: Vec<u8>,
  ) -> FlowyResult<EncodedCollab> {
    let database_data = DatabaseData::from_json_bytes(data)?;
    if database_data.views.is_empty() {
      return Err(FlowyError::invalid_data().with_context("The database data is empty"));
    }

    // choose the first view as the display view. The new database_view_id is the ID in the Folder.
    let database_view_id = database_data.views[0].id.clone();
    let create_database_params = CreateDatabaseParams::from_database_data(
      database_data,
      &database_view_id,
      new_database_view_id,
    );

    let lock = self.workspace_database()?;
    let mut wdb = lock.write().await;
    let database = wdb.create_database(create_database_params).await?;
    drop(wdb);

    let encoded_collab = database
      .read()
      .await
      .encode_collab_v1(|collab| CollabType::Database.validate_require_data(collab))
      .map_err(|err| FlowyError::internal().with_context(err))?;
    Ok(encoded_collab)
  }

  /// When duplicating a database view, it will duplicate all the database views and replace the duplicated
  /// database_view_id with the new_database_view_id. The new database id is the ID created by Folder.
  #[tracing::instrument(level = "trace", skip_all, err)]
  pub async fn duplicate_database(
    &self,
    database_view_id: &str,
    new_database_view_id: &str,
  ) -> FlowyResult<EncodedCollab> {
    let lock = self.workspace_database()?;
    let mut wdb = lock.write().await;
    let database = wdb
      .duplicate_database(database_view_id, new_database_view_id)
      .await?;
    drop(wdb);

    let encoded_collab = database
      .read()
      .await
      .encode_collab_v1(|collab| CollabType::Database.validate_require_data(collab))
      .map_err(|err| FlowyError::internal().with_context(err))?;
    Ok(encoded_collab)
  }

  pub async fn import_database(
    &self,
    params: CreateDatabaseParams,
  ) -> FlowyResult<Arc<RwLock<Database>>> {
    let lock = self.workspace_database()?;
    let mut wdb = lock.write().await;
    let database = wdb.create_database(params).await?;
    drop(wdb);

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
    let workspace_database = self.workspace_database()?;
    let mut wdb = workspace_database.write().await;
    let mut params = CreateViewParams::new(database_id.clone(), database_view_id, name, layout);
    if let Ok(database) = wdb.get_or_init_database(&database_id).await {
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
    let params = match format {
      CSVFormat::Original => {
        let mut csv_template = CSVTemplate::try_from_reader(content.as_bytes(), true, None)?;
        csv_template.reset_view_id(view_id.clone());

        let database_template = csv_template.try_into_database_template(None).await?;
        database_template.into_params()
      },

      CSVFormat::META => {
        let cloned_view_id = view_id.clone();
        tokio::task::spawn_blocking(move || {
          CSVImporter.import_csv_from_string(cloned_view_id, content, format)
        })
        .await
        .map_err(internal_error)??
      },
    };

    let database_id = params.database_id.clone();
    let database = self.import_database(params).await?;
    let encoded_database = database.read().await.encode_database_collabs().await?;
    let encoded_collabs = std::iter::once(encoded_database.encoded_database_collab)
      .chain(encoded_database.encoded_row_collabs.into_iter())
      .collect::<Vec<_>>();

    let result = ImportResult {
      database_id,
      view_id,
      encoded_collabs,
    };
    info!("import csv result: {}", result);
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
    let database = self.get_database_editor_with_view_id(view_id).await?;
    database.export_csv(style).await
  }

  pub async fn update_database_layout(
    &self,
    view_id: &str,
    layout: DatabaseLayoutPB,
  ) -> FlowyResult<()> {
    let database = self.get_database_editor_with_view_id(view_id).await?;
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

  fn workspace_database(&self) -> FlowyResult<Arc<RwLock<WorkspaceDatabaseManager>>> {
    self
      .workspace_database_manager
      .load_full()
      .ok_or_else(|| FlowyError::internal().with_context("Workspace database not initialized"))
  }

  #[instrument(level = "debug", skip_all)]
  pub async fn summarize_row(
    &self,
    view_id: String,
    row_id: RowId,
    field_id: String,
  ) -> FlowyResult<()> {
    let database = self.get_database_editor_with_view_id(&view_id).await?;
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
    let database = self.get_database_editor_with_view_id(&view_id).await?;
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

struct WorkspaceDatabaseCollabServiceImpl {
  is_local_user: bool,
  user: Arc<dyn DatabaseUser>,
  collab_builder: Arc<AppFlowyCollabBuilder>,
  persistence: Arc<dyn DatabaseCollabPersistenceService>,
  cloud_service: Arc<dyn DatabaseCloudService>,
}

impl WorkspaceDatabaseCollabServiceImpl {
  fn new(
    is_local_user: bool,
    user: Arc<dyn DatabaseUser>,
    collab_builder: Arc<AppFlowyCollabBuilder>,
    cloud_service: Arc<dyn DatabaseCloudService>,
  ) -> Self {
    let persistence = DatabasePersistenceImpl { user: user.clone() };
    Self {
      is_local_user,
      user,
      collab_builder,
      persistence: Arc::new(persistence),
      cloud_service,
    }
  }

  async fn get_encode_collab(
    &self,
    object_id: &str,
    object_ty: CollabType,
  ) -> Result<Option<EncodedCollab>, DatabaseError> {
    let workspace_id = self.user.workspace_id().unwrap();
    trace!("[Database]: fetch {}:{} from remote", object_id, object_ty);
    let encode_collab = self
      .cloud_service
      .get_database_encode_collab(object_id, object_ty, &workspace_id)
      .await
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    Ok(encode_collab)
  }

  async fn batch_get_encode_collab(
    &self,
    object_ids: Vec<String>,
    object_ty: CollabType,
  ) -> Result<EncodeCollabByOid, DatabaseError> {
    let workspace_id = self
      .user
      .workspace_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    let updates = self
      .cloud_service
      .batch_get_database_encode_collab(object_ids, object_ty, &workspace_id)
      .await
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    Ok(updates)
  }

  fn collab_db(&self) -> Result<Weak<CollabKVDB>, DatabaseError> {
    let uid = self
      .user
      .user_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    self
      .user
      .collab_db(uid)
      .map_err(|err| DatabaseError::Internal(err.into()))
  }

  fn build_collab_object(
    &self,
    object_id: &str,
    object_type: CollabType,
  ) -> Result<CollabObject, DatabaseError> {
    let uid = self
      .user
      .user_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    let workspace_id = self
      .user
      .workspace_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    let object = self
      .collab_builder
      .collab_object(&workspace_id, uid, object_id, object_type)
      .map_err(|err| DatabaseError::Internal(anyhow!("Failed to build collab object: {}", err)))?;
    Ok(object)
  }
}

#[async_trait]
impl DatabaseCollabService for WorkspaceDatabaseCollabServiceImpl {
  ///NOTE: this method doesn't initialize plugins, however it is passed into WorkspaceDatabase,
  /// therefore all Database/DatabaseRow creation methods must initialize plugins thmselves.
  #[instrument(level = "trace", skip_all)]
  async fn build_collab(
    &self,
    object_id: &str,
    collab_type: CollabType,
    encoded_collab: Option<(EncodedCollab, bool)>,
  ) -> Result<Collab, DatabaseError> {
    let object = self.build_collab_object(object_id, collab_type.clone())?;
    let data_source = if self.persistence.is_collab_exist(object_id) {
      if encoded_collab.is_some() {
        warn!(
          "build collab: {}:{} with both local and remote encode collab",
          collab_type, object_id
        );
      }

      trace!(
        "build collab: {}:{} from local encode collab",
        collab_type,
        object_id
      );
      CollabPersistenceImpl {
        persistence: Some(self.persistence.clone()),
      }
      .into()
    } else {
      match encoded_collab {
        None => {
          info!(
            "build collab: fetch {}:{} from remote, is_new:{}",
            collab_type,
            object_id,
            encoded_collab.is_none(),
          );
          match self.get_encode_collab(object_id, collab_type.clone()).await {
            Ok(Some(encode_collab)) => {
              info!(
                "build collab: {}:{} with remote encode collab, {} bytes",
                collab_type,
                object_id,
                encode_collab.doc_state.len()
              );
              DataSource::from(encode_collab)
            },
            Ok(None) => {
              if self.is_local_user {
                info!(
                  "build collab: {}:{} with empty encode collab",
                  collab_type, object_id
                );
                CollabPersistenceImpl {
                  persistence: Some(self.persistence.clone()),
                }
                .into()
              } else {
                return Err(DatabaseError::RecordNotFound);
              }
            },
            Err(err) => {
              if !matches!(err, DatabaseError::ActionCancelled) {
                error!("build collab: failed to get encode collab: {}", err);
              }
              return Err(err);
            },
          }
        },
        Some((encoded_collab, _)) => {
          info!(
            "build collab: {}:{} with new encode collab, {} bytes",
            collab_type,
            object_id,
            encoded_collab.doc_state.len()
          );
          self
            .persistence
            .save_collab(object_id, encoded_collab.clone())?;

          // TODO(nathan): cover database rows and other database collab type
          if matches!(collab_type, CollabType::Database) {
            if let Ok(workspace_id) = self.user.workspace_id() {
              let object_id = object_id.to_string();
              let cloned_encoded_collab = encoded_collab.clone();
              let cloud_service = self.cloud_service.clone();
              tokio::spawn(async move {
                let _ = cloud_service
                  .create_database_encode_collab(
                    &object_id,
                    collab_type,
                    &workspace_id,
                    cloned_encoded_collab,
                  )
                  .await;
              });
            }
          }
          encoded_collab.into()
        },
      }
    };

    let collab_db = self.collab_db()?;
    let collab = self
      .collab_builder
      .build_collab(&object, &collab_db, data_source)?;
    Ok(collab)
  }

  async fn get_collabs(
    &self,
    mut object_ids: Vec<String>,
    collab_type: CollabType,
  ) -> Result<EncodeCollabByOid, DatabaseError> {
    if object_ids.is_empty() {
      return Ok(EncodeCollabByOid::new());
    }
    let mut encoded_collab_by_id = EncodeCollabByOid::new();
    // 1. Collect local disk collabs into a HashMap
    let local_disk_encoded_collab: HashMap<String, EncodedCollab> = object_ids
      .par_iter()
      .filter_map(|object_id| {
        self
          .persistence
          .get_encoded_collab(object_id.as_str(), collab_type.clone())
          .map(|encoded_collab| (object_id.clone(), encoded_collab))
      })
      .collect();
    trace!(
      "[Database]: load {} database row from local disk",
      local_disk_encoded_collab.len()
    );
    object_ids.retain(|object_id| !local_disk_encoded_collab.contains_key(object_id));
    for (k, v) in local_disk_encoded_collab {
      encoded_collab_by_id.insert(k, v);
    }

    // 2. Fetch remaining collabs from remote
    let remote_collabs = self
      .batch_get_encode_collab(object_ids, collab_type)
      .await?;

    trace!(
      "[Database]: load {} database row from remote",
      remote_collabs.len()
    );
    for (k, v) in remote_collabs {
      encoded_collab_by_id.insert(k, v);
    }
    Ok(encoded_collab_by_id)
  }

  fn persistence(&self) -> Option<Arc<dyn DatabaseCollabPersistenceService>> {
    Some(Arc::new(DatabasePersistenceImpl {
      user: self.user.clone(),
    }))
  }
}

pub struct DatabasePersistenceImpl {
  user: Arc<dyn DatabaseUser>,
}

impl DatabaseCollabPersistenceService for DatabasePersistenceImpl {
  fn load_collab(&self, collab: &mut Collab) {
    let result = self
      .user
      .user_id()
      .map(|uid| (uid, self.user.collab_db(uid).map(|weak| weak.upgrade())));

    if let Ok((uid, Ok(Some(collab_db)))) = result {
      let object_id = collab.object_id().to_string();
      let db_read = collab_db.read_txn();
      if !db_read.is_exist(uid, &object_id) {
        trace!(
          "[Database]: collab:{} not exist in local storage",
          object_id
        );
        return;
      }

      trace!("[Database]: start loading collab:{} from disk", object_id);
      let mut txn = collab.transact_mut();
      match db_read.load_doc_with_txn(uid, &object_id, &mut txn) {
        Ok(update_count) => {
          trace!(
            "[Database]: did load collab:{}, update_count:{}",
            object_id,
            update_count
          );
        },
        Err(err) => {
          if !err.is_record_not_found() {
            error!("[Database]: load collab:{} failed:{}", object_id, err);
          }
        },
      }
    }
  }

  fn get_encoded_collab(&self, object_id: &str, collab_type: CollabType) -> Option<EncodedCollab> {
    let uid = self.user.user_id().ok()?;
    let db = self.user.collab_db(uid).ok()?.upgrade()?;
    let read_txn = db.read_txn();
    if !read_txn.is_exist(uid, &object_id) {
      return None;
    }

    let mut collab = Collab::new_with_origin(CollabOrigin::Empty, object_id, vec![], false);
    let mut txn = collab.transact_mut();
    let _ = read_txn.load_doc_with_txn(uid, &object_id, &mut txn);
    drop(txn);

    collab
      .encode_collab_v1(|collab| collab_type.validate_require_data(collab))
      .ok()
  }

  fn delete_collab(&self, object_id: &str) -> Result<(), DatabaseError> {
    let uid = self
      .user
      .user_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    if let Ok(Some(collab_db)) = self.user.collab_db(uid).map(|weak| weak.upgrade()) {
      let write_txn = collab_db.write_txn();
      write_txn.delete_doc(uid, object_id).unwrap();
      write_txn
        .commit_transaction()
        .map_err(|err| DatabaseError::Internal(anyhow!("failed to commit transaction: {}", err)))?;
    }
    Ok(())
  }

  fn save_collab(
    &self,
    object_id: &str,
    encoded_collab: EncodedCollab,
  ) -> Result<(), DatabaseError> {
    let uid = self
      .user
      .user_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    if let Ok(Some(collab_db)) = self.user.collab_db(uid).map(|weak| weak.upgrade()) {
      let write_txn = collab_db.write_txn();
      write_txn
        .flush_doc(
          uid,
          object_id,
          encoded_collab.state_vector.to_vec(),
          encoded_collab.doc_state.to_vec(),
        )
        .map_err(|err| DatabaseError::Internal(anyhow!("failed to flush doc: {}", err)))?;
      write_txn
        .commit_transaction()
        .map_err(|err| DatabaseError::Internal(anyhow!("failed to commit transaction: {}", err)))?;
    }
    Ok(())
  }

  fn is_collab_exist(&self, object_id: &str) -> bool {
    match self
      .user
      .user_id()
      .map_err(|err| DatabaseError::Internal(err.into()))
    {
      Ok(uid) => {
        if let Ok(Some(collab_db)) = self.user.collab_db(uid).map(|weak| weak.upgrade()) {
          let read_txn = collab_db.read_txn();
          return read_txn.is_exist(uid, object_id);
        }
        false
      },
      Err(_) => false,
    }
  }

  fn flush_collabs(
    &self,
    encoded_collabs: Vec<(String, EncodedCollab)>,
  ) -> Result<(), DatabaseError> {
    let uid = self
      .user
      .user_id()
      .map_err(|err| DatabaseError::Internal(err.into()))?;
    if let Ok(Some(collab_db)) = self.user.collab_db(uid).map(|weak| weak.upgrade()) {
      let write_txn = collab_db.write_txn();
      for (object_id, encode_collab) in encoded_collabs {
        write_txn
          .flush_doc(
            uid,
            &object_id,
            encode_collab.state_vector.to_vec(),
            encode_collab.doc_state.to_vec(),
          )
          .map_err(|err| DatabaseError::Internal(anyhow!("failed to flush doc: {}", err)))?;
      }
      write_txn
        .commit_transaction()
        .map_err(|err| DatabaseError::Internal(anyhow!("failed to commit transaction: {}", err)))?;
    }
    Ok(())
  }

  fn is_row_exist_partition(&self, row_ids: Vec<RowId>) -> (Vec<RowId>, Vec<RowId>) {
    if let Ok(uid) = self.user.user_id() {
      if let Ok(Some(collab_db)) = self.user.collab_db(uid).map(|weak| weak.upgrade()) {
        let read_txn = collab_db.read_txn();
        return row_ids
          .into_iter()
          .partition(|row_id| read_txn.is_exist(uid, row_id.as_ref()));
      }
    }

    (vec![], row_ids)
  }
}
async fn open_database_with_retry(
  workspace_database_manager: Arc<RwLock<WorkspaceDatabaseManager>>,
  database_id: &str,
) -> Result<Arc<RwLock<Database>>, DatabaseError> {
  let max_retries = 3;
  let retry_interval = Duration::from_secs(4);
  for attempt in 1..=max_retries {
    trace!(
      "[Database]: attempt {} to open database:{}",
      attempt,
      database_id
    );

    let result = workspace_database_manager
      .try_read()
      .map_err(|err| DatabaseError::Internal(anyhow!("workspace database lock fail: {}", err)))?
      .get_or_init_database(database_id)
      .await;

    // Attempt to open the database
    match result {
      Ok(database) => return Ok(database),
      Err(err) => {
        if matches!(err, DatabaseError::RecordNotFound)
          || matches!(err, DatabaseError::NoRequiredData(_))
        {
          error!(
            "[Database]: retry {} to open database:{}, error:{}",
            attempt, database_id, err
          );

          if attempt < max_retries {
            tokio::time::sleep(retry_interval).await;
          } else {
            error!(
              "[Database]: exhausted retries to open database:{}, error:{}",
              database_id, err
            );
            return Err(err);
          }
        } else {
          error!(
            "[Database]: stop retrying to open database:{}, error:{}",
            database_id, err
          );
          return Err(err);
        }
      },
    }
  }

  Err(DatabaseError::Internal(anyhow!(
    "Exhausted retries to open database: {}",
    database_id
  )))
}
