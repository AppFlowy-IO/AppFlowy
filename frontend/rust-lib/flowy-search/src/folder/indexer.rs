use std::{
  any::Any,
  collections::HashMap,
  fs,
  ops::Deref,
  path::Path,
  sync::{Arc, Mutex, MutexGuard, Weak},
};

use crate::{
  entities::{ResultIconTypePB, SearchFilterPB, SearchResultPB},
  folder::schema::{
    FolderSchema, FOLDER_ICON_FIELD_NAME, FOLDER_ICON_TY_FIELD_NAME, FOLDER_ID_FIELD_NAME,
    FOLDER_TITLE_FIELD_NAME, FOLDER_WORKSPACE_ID_FIELD_NAME,
  },
};
use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::{folder_diff::FolderViewChange, View, ViewIcon, ViewIndexContent, ViewLayout};
use flowy_error::{FlowyError, FlowyResult};
use flowy_search_pub::entities::{FolderIndexManager, IndexManager, IndexableData};
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_dispatch::prelude::af_spawn;
use strsim::levenshtein;
use tantivy::{
  collector::TopDocs, directory::MmapDirectory, doc, query::QueryParser, schema::Field, Index,
  IndexReader, IndexWriter, Term,
};

use super::entities::FolderIndexData;

#[derive(Clone)]
pub struct FolderIndexManagerImpl {
  folder_schema: Option<FolderSchema>,
  index: Option<Index>,
  index_reader: Option<IndexReader>,
  index_writer: Option<Arc<Mutex<IndexWriter>>>,
}

const FOLDER_INDEX_DIR: &str = "folder_index";

impl FolderIndexManagerImpl {
  pub fn new(auth_user: Option<Weak<AuthenticateUser>>) -> Self {
    let auth_user = match auth_user {
      Some(auth_user) => auth_user,
      None => {
        return FolderIndexManagerImpl::empty();
      },
    };

    // AuthenticateUser is required to get the index path
    let authenticate_user = auth_user.upgrade();

    // Storage path is the users data path with an index directory
    // Eg. /usr/flowy-data/indexes
    let storage_path = match authenticate_user {
      Some(auth_user) => auth_user.get_index_path(),
      None => {
        tracing::error!("FolderIndexManager: AuthenticateUser is not available");
        return FolderIndexManagerImpl::empty();
      },
    };

    // We check if the `folder_index` directory exists, if not we create it
    let index_path = storage_path.join(Path::new(FOLDER_INDEX_DIR));
    if !index_path.exists() {
      let res = fs::create_dir_all(&index_path);
      if let Err(e) = res {
        tracing::error!(
          "FolderIndexManager failed to create index directory: {:?}",
          e
        );
        return FolderIndexManagerImpl::empty();
      }
    }

    // The folder schema is used to define the fields of the index along
    // with how they are stored and if the field is indexed
    let folder_schema = FolderSchema::new();

    // We open the existing or newly created folder_index directory
    // This is required by the Tantivy Index, as it will use it to store
    // and read index data
    let index = match MmapDirectory::open(index_path) {
      // We open or create an index that takes the directory r/w and the schema.
      Ok(dir) => match Index::open_or_create(dir, folder_schema.schema.clone()) {
        Ok(index) => index,
        Err(e) => {
          tracing::error!("FolderIndexManager failed to open index: {:?}", e);
          return FolderIndexManagerImpl::empty();
        },
      },
      Err(e) => {
        tracing::error!("FolderIndexManager failed to open index directory: {:?}", e);
        return FolderIndexManagerImpl::empty();
      },
    };

    // We only need one IndexReader per index
    let index_reader = index.reader();
    let index_writer = index.writer(50_000_000);

    let (index_reader, index_writer) = match (index_reader, index_writer) {
      (Ok(reader), Ok(writer)) => (reader, writer),
      _ => {
        tracing::error!("FolderIndexManager failed to instantiate index writer and/or reader");
        return FolderIndexManagerImpl::empty();
      },
    };

    Self {
      folder_schema: Some(folder_schema),
      index: Some(index),
      index_reader: Some(index_reader),
      index_writer: Some(Arc::new(Mutex::new(index_writer))),
    }
  }

  fn index_all(&self, indexes: Vec<IndexableData>) -> Result<(), FlowyError> {
    if indexes.is_empty() {
      return Ok(());
    }

    let mut index_writer = self.get_index_writer()?;
    let folder_schema = self.get_folder_schema()?;

    let id_field = folder_schema.schema.get_field(FOLDER_ID_FIELD_NAME)?;
    let title_field = folder_schema.schema.get_field(FOLDER_TITLE_FIELD_NAME)?;
    let icon_field = folder_schema.schema.get_field(FOLDER_ICON_FIELD_NAME)?;
    let icon_ty_field = folder_schema.schema.get_field(FOLDER_ICON_TY_FIELD_NAME)?;
    let workspace_id_field = folder_schema
      .schema
      .get_field(FOLDER_WORKSPACE_ID_FIELD_NAME)?;

    for data in indexes {
      let (icon, icon_ty) = self.extract_icon(data.icon, data.layout);

      let _ = index_writer.add_document(doc![
        id_field => data.id.clone(),
        title_field => data.data.clone(),
        icon_field => icon.unwrap_or_default(),
        icon_ty_field => icon_ty,
        workspace_id_field => data.workspace_id.clone(),
      ]);
    }

    index_writer.commit()?;

    Ok(())
  }

  pub fn num_docs(&self) -> u64 {
    self
      .index_reader
      .clone()
      .map(|reader| reader.searcher().num_docs())
      .unwrap_or(0)
  }

  fn empty() -> Self {
    Self {
      folder_schema: None,
      index: None,
      index_reader: None,
      index_writer: None,
    }
  }

  fn get_index_writer(&self) -> FlowyResult<MutexGuard<IndexWriter>> {
    match &self.index_writer {
      Some(index_writer) => match index_writer.deref().lock() {
        Ok(writer) => Ok(writer),
        Err(e) => {
          tracing::error!("FolderIndexManager failed to lock index writer: {:?}", e);
          Err(FlowyError::folder_index_manager_unavailable())
        },
      },
      None => Err(FlowyError::folder_index_manager_unavailable()),
    }
  }

  fn get_folder_schema(&self) -> FlowyResult<FolderSchema> {
    match &self.folder_schema {
      Some(folder_schema) => Ok(folder_schema.clone()),
      None => Err(FlowyError::folder_index_manager_unavailable()),
    }
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
      let layout_ty: i64 = view_layout.into();
      icon = Some(layout_ty.to_string());
    }

    (icon, icon_ty)
  }

  pub fn search(
    &self,
    query: String,
    _filter: Option<SearchFilterPB>,
  ) -> Result<Vec<SearchResultPB>, FlowyError> {
    let folder_schema = self.get_folder_schema()?;

    let (index, index_reader) = self
      .index
      .as_ref()
      .zip(self.index_reader.as_ref())
      .ok_or_else(FlowyError::folder_index_manager_unavailable)?;

    let title_field = folder_schema.schema.get_field(FOLDER_TITLE_FIELD_NAME)?;

    let length = query.len();
    let distance: u8 = if length >= 2 { 2 } else { 1 };

    let mut query_parser = QueryParser::for_index(&index.clone(), vec![title_field]);
    query_parser.set_field_fuzzy(title_field, true, distance, true);
    let built_query = query_parser.parse_query(&query.clone())?;

    let searcher = index_reader.searcher();
    let mut search_results: Vec<SearchResultPB> = vec![];
    let top_docs = searcher.search(&built_query, &TopDocs::with_limit(10))?;
    for (_score, doc_address) in top_docs {
      let retrieved_doc = searcher.doc(doc_address)?;

      let mut content = HashMap::new();
      let named_doc = folder_schema.schema.to_named_doc(&retrieved_doc);
      for (k, v) in named_doc.0 {
        content.insert(k, v[0].clone());
      }

      if content.is_empty() {
        continue;
      }

      let s = serde_json::to_string(&content)?;
      let result: SearchResultPB = serde_json::from_str::<FolderIndexData>(&s)?.into();
      let score = self.score_result(&query, &result.data);
      search_results.push(result.with_score(score));
    }

    Ok(search_results)
  }

  // Score result by distance
  fn score_result(&self, query: &str, term: &str) -> f64 {
    let distance = levenshtein(query, term) as f64;
    1.0 / (distance + 1.0)
  }

  fn get_schema_fields(&self) -> Result<(Field, Field, Field, Field, Field), FlowyError> {
    let folder_schema = match self.folder_schema.clone() {
      Some(schema) => schema,
      _ => return Err(FlowyError::folder_index_manager_unavailable()),
    };

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
}

impl IndexManager for FolderIndexManagerImpl {
  fn is_indexed(&self) -> bool {
    self
      .index_reader
      .clone()
      .map(|reader| reader.searcher().num_docs() > 0)
      .unwrap_or(false)
  }

  fn set_index_content_receiver(&self, mut rx: IndexContentReceiver, workspace_id: String) {
    let indexer = self.clone();
    let wid = workspace_id.clone();
    af_spawn(async move {
      while let Ok(msg) = rx.recv().await {
        tracing::warn!("[Indexer] Message received: {:?}", msg);
        match msg {
          IndexContent::Create(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              tracing::warn!("[Indexer] CREATE: {:?}", view);

              let _ = indexer.add_index(IndexableData {
                id: view.id,
                data: view.name,
                icon: view.icon,
                layout: view.layout,
                workspace_id: wid.clone(),
              });
            },
            Err(err) => tracing::error!("FolderIndexManager error deserialize: {:?}", err),
          },
          IndexContent::Update(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              tracing::warn!("[Indexer] UPDATE: {:?}", view);
              let _ = indexer.update_index(IndexableData {
                id: view.id,
                data: view.name,
                icon: view.icon,
                layout: view.layout,
                workspace_id: wid.clone(),
              });
            },
            Err(err) => tracing::error!("FolderIndexManager error deserialize: {:?}", err),
          },
          IndexContent::Delete(ids) => {
            tracing::warn!("[Indexer] DELETE: {:?}", ids);
            if let Err(e) = indexer.remove_indices(ids) {
              tracing::error!("FolderIndexManager error deserialize: {:?}", e);
            }
          },
        }
      }
    });
  }

  fn update_index(&self, data: IndexableData) -> Result<(), FlowyError> {
    let mut index_writer = self.get_index_writer()?;

    let (id_field, title_field, icon_field, icon_ty_field, workspace_id_field) =
      self.get_schema_fields()?;

    let delete_term = Term::from_field_text(id_field, &data.id.clone());

    // Remove old index
    index_writer.delete_term(delete_term);

    let (icon, icon_ty) = self.extract_icon(data.icon, data.layout);

    // Add new index
    let _ = index_writer.add_document(doc![
      id_field => data.id.clone(),
      title_field => data.data,
      icon_field => icon.unwrap_or_default(),
      icon_ty_field => icon_ty,
      workspace_id_field => data.workspace_id.clone(),
    ]);

    index_writer.commit()?;

    Ok(())
  }

  fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError> {
    let mut index_writer = self.get_index_writer()?;

    let folder_schema = self.get_folder_schema()?;
    let id_field = folder_schema.schema.get_field(FOLDER_ID_FIELD_NAME)?;
    for id in ids {
      let delete_term = Term::from_field_text(id_field, &id);
      index_writer.delete_term(delete_term);
    }

    index_writer.commit()?;

    Ok(())
  }

  fn add_index(&self, data: IndexableData) -> Result<(), FlowyError> {
    let mut index_writer = self.get_index_writer()?;

    let (id_field, title_field, icon_field, icon_ty_field, workspace_id_field) =
      self.get_schema_fields()?;

    let (icon, icon_ty) = self.extract_icon(data.icon, data.layout);

    // Add new index
    let _ = index_writer.add_document(doc![
      id_field => data.id,
      title_field => data.data,
      icon_field => icon.unwrap_or_default(),
      icon_ty_field => icon_ty,
      workspace_id_field => data.workspace_id,
    ]);

    index_writer.commit()?;

    Ok(())
  }

  /// Removes all indexes that are related by workspace id. This is useful
  /// for cleaning indexes when eg. removing/leaving a workspace.
  ///
  fn remove_indices_for_workspace(&self, workspace_id: String) -> Result<(), FlowyError> {
    let mut index_writer = self.get_index_writer()?;

    let folder_schema = self.get_folder_schema()?;
    let id_field = folder_schema
      .schema
      .get_field(FOLDER_WORKSPACE_ID_FIELD_NAME)?;
    let delete_term = Term::from_field_text(id_field, &workspace_id);
    index_writer.delete_term(delete_term);

    index_writer.commit()?;

    Ok(())
  }

  fn as_any(&self) -> &dyn Any {
    self
  }
}

impl FolderIndexManager for FolderIndexManagerImpl {
  fn index_all_views(&self, views: Vec<Arc<View>>, workspace_id: String) {
    let indexable_data = views
      .into_iter()
      .map(|view| IndexableData::from_view(view, workspace_id.clone()))
      .collect();

    let _ = self.index_all(indexable_data);
  }

  fn index_view_changes(
    &self,
    views: Vec<Arc<View>>,
    changes: Vec<FolderViewChange>,
    workspace_id: String,
  ) {
    let mut views_iter = views.into_iter();
    for change in changes {
      match change {
        FolderViewChange::Inserted { view_id } => {
          let view = views_iter.find(|view| view.id == view_id);
          if let Some(view) = view {
            let indexable_data = IndexableData::from_view(view, workspace_id.clone());
            let _ = self.add_index(indexable_data);
          }
        },
        FolderViewChange::Updated { view_id } => {
          let view = views_iter.find(|view| view.id == view_id);
          if let Some(view) = view {
            let indexable_data = IndexableData::from_view(view, workspace_id.clone());
            let _ = self.update_index(indexable_data);
          }
        },
        FolderViewChange::Deleted { view_ids } => {
          tracing::warn!("[Indexer] ViewChange Reached Deleted: {:?}", view_ids);
          let _ = self.remove_indices(view_ids);
        },
      };
    }
  }
}
