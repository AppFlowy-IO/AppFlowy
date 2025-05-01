use super::entities::FolderIndexData;
use crate::entities::{LocalSearchResponseItemPB, ResultIconTypePB};
use crate::folder::schema::{
  FolderTantivySchema, FOLDER_ICON_FIELD_NAME, FOLDER_ICON_TY_FIELD_NAME, FOLDER_ID_FIELD_NAME,
  FOLDER_TITLE_FIELD_NAME, FOLDER_WORKSPACE_ID_FIELD_NAME,
};
use collab_folder::{ViewIcon, ViewIndexContent, ViewLayout};
use flowy_error::{FlowyError, FlowyResult};
use flowy_user::services::authenticate_user::AuthenticateUser;
use std::path::PathBuf;
use std::sync::{Arc, Weak};
use std::{collections::HashMap, fs};
use tantivy::{
  collector::TopDocs, directory::MmapDirectory, query::QueryParser, schema::Field, Document, Index,
  IndexReader, IndexWriter, TantivyDocument, TantivyError, Term,
};
use tokio::sync::RwLock;
use tracing::{error, info};
use uuid::Uuid;

pub struct FolderTantivyState {
  pub path: PathBuf,
  pub index: Index,
  pub folder_schema: FolderTantivySchema,
  pub index_reader: IndexReader,
  pub index_writer: IndexWriter,
}

impl Drop for FolderTantivyState {
  fn drop(&mut self) {
    tracing::trace!("Dropping FolderTantivyState at {:?}", self.path);
  }
}

#[derive(Clone)]
pub struct FolderIndexManagerImpl {
  auth_user: Weak<AuthenticateUser>,
  state: Arc<RwLock<Option<FolderTantivyState>>>,
}

impl FolderIndexManagerImpl {
  pub fn new(auth_user: Weak<AuthenticateUser>) -> Self {
    Self {
      auth_user,
      state: Arc::new(RwLock::new(None)),
    }
  }

  async fn with_writer<F, R>(&self, f: F) -> FlowyResult<R>
  where
    F: FnOnce(&mut IndexWriter, &FolderTantivySchema) -> FlowyResult<R>,
  {
    let mut lock = self.state.write().await;
    if let Some(ref mut state) = *lock {
      f(&mut state.index_writer, &state.folder_schema)
    } else {
      Err(FlowyError::internal().with_context("Index not initialized. Call initialize first"))
    }
  }

  /// Initializes the state using the workspace directory.
  async fn initialize(&self, workspace_id: &Uuid) -> FlowyResult<()> {
    if let Some(state) = self.state.write().await.take() {
      drop(state);
    }

    // Since the directory lock may not be immediately released,
    // a workaround is implemented by waiting for 3 seconds before proceeding further. This delay helps
    // to avoid errors related to trying to open an index directory while an IndexWriter is still active.
    //
    // Also, we don't need to initialize the indexer immediately.
    tokio::time::sleep(tokio::time::Duration::from_secs(3)).await;

    let auth_user = self
      .auth_user
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("AuthenticateUser is not available"))?;

    let index_path = auth_user.get_index_path()?.join(workspace_id.to_string());
    if !index_path.exists() {
      fs::create_dir_all(&index_path).map_err(|e| {
        error!("Failed to create folder index directory: {:?}", e);
        FlowyError::internal().with_context("Failed to create folder index")
      })?;
    }

    info!("Folder indexer initialized at: {:?}", index_path);
    let folder_schema = FolderTantivySchema::new();
    let dir = MmapDirectory::open(index_path.clone())?;
    let index = Index::open_or_create(dir, folder_schema.schema.clone())?;
    let index_reader = index.reader()?;

    let memory_size = 15_000_000; // minimum value
    let index_writer = match index.writer::<_>(memory_size) {
      Ok(index_writer) => index_writer,
      Err(err) => {
        if let TantivyError::LockFailure(_, _) = err {
          error!(
            "Failed to acquire lock for index writer: {:?}, retry later",
            err
          );
          tokio::time::sleep(tokio::time::Duration::from_secs(3)).await;
        }
        index.writer::<_>(memory_size)?
      },
    };

    *self.state.write().await = Some(FolderTantivyState {
      path: index_path,
      index,
      folder_schema,
      index_reader,
      index_writer,
    });

    Ok(())
  }

  fn extract_icon(
    &self,
    view_icon: Option<ViewIcon>,
    view_layout: ViewLayout,
  ) -> (Option<String>, i64) {
    let icon_ty: i64;
    let icon: Option<String>;

    if view_icon.clone().is_some_and(|v| !v.value.is_empty()) {
      let view_icon = view_icon.unwrap();
      let result_icon_ty: ResultIconTypePB = view_icon.ty.into();
      icon_ty = result_icon_ty.into();
      icon = Some(view_icon.value);
    } else {
      icon_ty = ResultIconTypePB::Icon.into();
      let layout_ty = view_layout as i64;
      icon = Some(layout_ty.to_string());
    }
    (icon, icon_ty)
  }

  /// Searches the index using the given query string.
  pub async fn search(&self, query: String) -> Result<Vec<LocalSearchResponseItemPB>, FlowyError> {
    let lock = self.state.read().await;
    let state = lock
      .as_ref()
      .ok_or_else(FlowyError::folder_index_manager_unavailable)?;
    let schema = &state.folder_schema;
    let index = &state.index;
    let reader = &state.index_reader;

    let title_field = schema.schema.get_field(FOLDER_TITLE_FIELD_NAME)?;
    let mut parser = QueryParser::for_index(index, vec![title_field]);
    parser.set_field_fuzzy(title_field, true, 2, true);

    let built_query = parser.parse_query(&query)?;
    let searcher = reader.searcher();
    let top_docs = searcher.search(&built_query, &TopDocs::with_limit(10))?;

    let mut results = Vec::new();
    for (_score, doc_address) in top_docs {
      let doc: TantivyDocument = searcher.doc(doc_address)?;
      let named_doc = doc.to_named_doc(&schema.schema);
      let mut content = HashMap::new();
      for (k, v) in named_doc.0 {
        content.insert(k, v[0].clone());
      }
      if !content.is_empty() {
        let s = serde_json::to_string(&content)?;
        let result: LocalSearchResponseItemPB = serde_json::from_str::<FolderIndexData>(&s)?.into();
        results.push(result);
      }
    }

    Ok(results)
  }
}

fn get_schema_fields(
  folder_schema: &FolderTantivySchema,
) -> Result<(Field, Field, Field, Field, Field), FlowyError> {
  let id_field = folder_schema.schema.get_field(FOLDER_ID_FIELD_NAME)?;
  let title_field = folder_schema.schema.get_field(FOLDER_TITLE_FIELD_NAME)?;
  let icon_field = folder_schema.schema.get_field(FOLDER_ICON_FIELD_NAME)?;
  let icon_ty_field = folder_schema.schema.get_field(FOLDER_ICON_TY_FIELD_NAME)?;
  let workspace_id_field = folder_schema
    .schema
    .get_field(FOLDER_WORKSPACE_ID_FIELD_NAME)?;

  Ok((
    id_field,
    title_field,
    icon_field,
    icon_ty_field,
    workspace_id_field,
  ))
}
