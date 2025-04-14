use crate::folder::schema::{
  FolderSchema, FOLDER_ICON_FIELD_NAME, FOLDER_ICON_TY_FIELD_NAME, FOLDER_ID_FIELD_NAME,
  FOLDER_TITLE_FIELD_NAME, FOLDER_WORKSPACE_ID_FIELD_NAME,
};
use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::{folder_diff::FolderViewChange, View, ViewIcon, ViewIndexContent, ViewLayout};
use flowy_error::{FlowyError, FlowyResult};
use flowy_search_pub::entities::{FolderIndexManager, IndexManager, IndexableData};
use flowy_user::services::authenticate_user::AuthenticateUser;
use std::sync::{Arc, Weak};
use std::{collections::HashMap, fs};

use super::entities::FolderIndexData;
use crate::entities::{LocalSearchResponseItemPB, ResultIconTypePB};
use lib_infra::async_trait::async_trait;
use tantivy::{
  collector::TopDocs, directory::MmapDirectory, doc, query::QueryParser, schema::Field, Document,
  Index, IndexReader, IndexWriter, TantivyDocument, Term,
};
use tokio::sync::RwLock;
use tracing::{error, info};
use uuid::Uuid;

pub struct TantivyState {
  pub index: Index,
  pub folder_schema: FolderSchema,
  pub index_reader: IndexReader,
  pub index_writer: IndexWriter,
}

const FOLDER_INDEX_DIR: &str = "folder_index";

#[derive(Clone)]
pub struct FolderIndexManagerImpl {
  auth_user: Weak<AuthenticateUser>,
  state: Arc<RwLock<Option<TantivyState>>>,
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
    F: FnOnce(&mut IndexWriter, &FolderSchema) -> FlowyResult<R>,
  {
    let mut lock = self.state.write().await;
    if let Some(ref mut state) = *lock {
      f(&mut state.index_writer, &state.folder_schema)
    } else {
      Err(FlowyError::internal().with_context("Index not initialized. Call initialize first"))
    }
  }

  /// Initializes the state using the workspace directory.
  async fn initialize_with_workspace(&self) -> FlowyResult<()> {
    let auth_user = self
      .auth_user
      .upgrade()
      .ok_or_else(|| FlowyError::internal().with_context("AuthenticateUser is not available"))?;

    let index_path = auth_user.get_index_path()?.join(FOLDER_INDEX_DIR);
    if !index_path.exists() {
      fs::create_dir_all(&index_path).map_err(|e| {
        error!("Failed to create folder index directory: {:?}", e);
        FlowyError::internal().with_context("Failed to create folder index")
      })?;
    }

    info!("Folder indexer initialized at: {:?}", index_path);
    let folder_schema = FolderSchema::new();
    let dir = MmapDirectory::open(index_path)?;
    let index = Index::open_or_create(dir, folder_schema.schema.clone())?;
    let index_reader = index.reader()?;
    let index_writer = index.writer(50_000_000)?;

    *self.state.write().await = Some(TantivyState {
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

  /// Simple implementation to index all given data by spawning async tasks.
  fn index_all(&self, data_vec: Vec<IndexableData>) -> Result<(), FlowyError> {
    for data in data_vec {
      let indexer = self.clone();
      tokio::spawn(async move {
        let _ = indexer.add_index(data).await;
      });
    }
    Ok(())
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

#[async_trait]
impl IndexManager for FolderIndexManagerImpl {
  async fn set_index_content_receiver(&self, mut rx: IndexContentReceiver, workspace_id: Uuid) {
    let indexer = self.clone();
    let wid = workspace_id;
    tokio::spawn(async move {
      while let Ok(msg) = rx.recv().await {
        match msg {
          IndexContent::Create(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = indexer
                .add_index(IndexableData {
                  id: view.id,
                  data: view.name,
                  icon: view.icon,
                  layout: view.layout,
                  workspace_id: wid,
                })
                .await;
            },
            Err(err) => tracing::error!("FolderIndexManager error deserialize (create): {:?}", err),
          },
          IndexContent::Update(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = indexer
                .update_index(IndexableData {
                  id: view.id,
                  data: view.name,
                  icon: view.icon,
                  layout: view.layout,
                  workspace_id: wid,
                })
                .await;
            },
            Err(err) => error!("FolderIndexManager error deserialize (update): {:?}", err),
          },
          IndexContent::Delete(ids) => {
            if let Err(e) = indexer.remove_indices(ids).await {
              error!("FolderIndexManager error (delete): {:?}", e);
            }
          },
        }
      }
    });
  }

  async fn add_index(&self, data: IndexableData) -> Result<(), FlowyError> {
    let (icon, icon_ty) = self.extract_icon(data.icon, data.layout);
    self
      .with_writer(|index_writer, folder_schema| {
        let (id_field, title_field, icon_field, icon_ty_field, workspace_id_field) =
          get_schema_fields(folder_schema)?;
        let _ = index_writer.add_document(doc![
            id_field => data.id,
            title_field => data.data,
            icon_field => icon.unwrap_or_default(),
            icon_ty_field => icon_ty,
            workspace_id_field => data.workspace_id.to_string(),
        ]);
        index_writer.commit()?;
        Ok(())
      })
      .await?;

    Ok(())
  }

  async fn update_index(&self, data: IndexableData) -> Result<(), FlowyError> {
    self
      .with_writer(|index_writer, folder_schema| {
        let (id_field, title_field, icon_field, icon_ty_field, workspace_id_field) =
          get_schema_fields(folder_schema)?;
        let delete_term = Term::from_field_text(id_field, &data.id);
        index_writer.delete_term(delete_term);

        let (icon, icon_ty) = self.extract_icon(data.icon, data.layout);
        let _ = index_writer.add_document(doc![
            id_field => data.id,
            title_field => data.data,
            icon_field => icon.unwrap_or_default(),
            icon_ty_field => icon_ty,
            workspace_id_field => data.workspace_id.to_string(),
        ]);

        index_writer.commit()?;
        Ok(())
      })
      .await?;

    Ok(())
  }

  async fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError> {
    self
      .with_writer(|index_writer, folder_schema| {
        let id_field = folder_schema.schema.get_field(FOLDER_ID_FIELD_NAME)?;
        for id in ids {
          let delete_term = Term::from_field_text(id_field, &id);
          index_writer.delete_term(delete_term);
        }

        index_writer.commit()?;
        Ok(())
      })
      .await?;

    Ok(())
  }

  async fn remove_indices_for_workspace(&self, workspace_id: Uuid) -> Result<(), FlowyError> {
    self
      .with_writer(|index_writer, folder_schema| {
        let id_field = folder_schema
          .schema
          .get_field(FOLDER_WORKSPACE_ID_FIELD_NAME)?;

        let delete_term = Term::from_field_text(id_field, &workspace_id.to_string());
        index_writer.delete_term(delete_term);
        index_writer.commit()?;
        Ok(())
      })
      .await?;
    Ok(())
  }

  async fn is_indexed(&self) -> bool {
    let lock = self.state.read().await;
    if let Some(ref state) = *lock {
      state.index_reader.searcher().num_docs() > 0
    } else {
      false
    }
  }
}

#[async_trait]
impl FolderIndexManager for FolderIndexManagerImpl {
  async fn initialize(&self) {
    if let Err(e) = self.initialize_with_workspace().await {
      error!("Failed to initialize FolderIndexManager: {:?}", e);
    }
  }

  fn index_all_views(&self, views: Vec<Arc<View>>, workspace_id: Uuid) {
    let indexable_data = views
      .into_iter()
      .map(|view| IndexableData::from_view(view, workspace_id))
      .collect();
    let _ = self.index_all(indexable_data);
  }

  fn index_view_changes(
    &self,
    views: Vec<Arc<View>>,
    changes: Vec<FolderViewChange>,
    workspace_id: Uuid,
  ) {
    let mut views_iter = views.into_iter();
    for change in changes {
      match change {
        FolderViewChange::Inserted { view_id } => {
          if let Some(view) = views_iter.find(|view| view.id == view_id) {
            let indexable_data = IndexableData::from_view(view, workspace_id);
            let f = self.clone();
            tokio::spawn(async move {
              let _ = f.add_index(indexable_data).await;
            });
          }
        },
        FolderViewChange::Updated { view_id } => {
          if let Some(view) = views_iter.find(|view| view.id == view_id) {
            let indexable_data = IndexableData::from_view(view, workspace_id);
            let f = self.clone();
            tokio::spawn(async move {
              let _ = f.update_index(indexable_data).await;
            });
          }
        },
        FolderViewChange::Deleted { view_ids } => {
          let f = self.clone();
          tokio::spawn(async move {
            let _ = f.remove_indices(view_ids).await;
          });
        },
      }
    }
  }
}

fn get_schema_fields(
  folder_schema: &FolderSchema,
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
