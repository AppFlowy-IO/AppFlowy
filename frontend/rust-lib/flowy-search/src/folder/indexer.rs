use std::{any::Any, collections::HashMap, fs, path::Path, sync::Weak};

use crate::{
  entities::ResultIconTypePB,
  folder::schema::{FolderSchema, FOLDER_ICON_FIELD_NAME, FOLDER_TITLE_FIELD_NAME},
};
use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::{ViewIcon, ViewIndexContent, ViewLayout};
use flowy_error::{FlowyError, FlowyResult};
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_dispatch::prelude::af_spawn;
use strsim::levenshtein;
use tantivy::{
  collector::TopDocs, directory::MmapDirectory, doc, query::QueryParser, Index, IndexReader,
  IndexWriter, Term,
};

use crate::{
  entities::SearchResultPB,
  services::indexer::{IndexManager, IndexableData},
};

use super::{
  entities::FolderIndexData,
  schema::{FOLDER_ICON_TY_FIELD_NAME, FOLDER_ID_FIELD_NAME},
};

#[derive(Clone)]
pub struct FolderIndexManager {
  folder_schema: FolderSchema,
  index: Index,
  index_reader: IndexReader,
}

const FOLDER_INDEX_DIR: &str = "folder_index";

impl FolderIndexManager {
  pub fn new(auth_user: Weak<AuthenticateUser>) -> FlowyResult<Self> {
    let authenticate_user = auth_user.upgrade();
    let storage_path = match authenticate_user {
      Some(auth_user) => auth_user.get_index_path(),
      None => {
        return Err(FlowyError::internal().with_context("The AuthenticateUser is not available"))
      },
    };

    let index_path = storage_path.join(Path::new(FOLDER_INDEX_DIR));
    if !index_path.exists() {
      fs::create_dir_all(&index_path)?;
    }

    let dir = MmapDirectory::open(index_path)?;
    let folder_schema = FolderSchema::new();

    let index = Index::open_or_create(dir, folder_schema.clone().schema)?;
    let index_reader = index.reader()?;

    Ok(Self {
      folder_schema,
      index,
      index_reader,
    })
  }

  fn get_index_writer(&self) -> FlowyResult<IndexWriter> {
    // Creates an IndexWriter with a heap size of 50 MB (50.000.000 bytes)
    Ok(self.index.writer(50_000_000)?)
  }

  fn extract_icon(
    &self,
    view_icon: Option<ViewIcon>,
    view_layout: ViewLayout,
  ) -> (Option<String>, i64) {
    let icon_ty: i64;
    let icon: Option<String>;

    if let Some(view_icon) = view_icon {
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

  pub fn search(&self, query: String) -> Result<Vec<SearchResultPB>, FlowyError> {
    let title_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_TITLE_FIELD_NAME)
      .unwrap();

    let length = query.len();
    let distance: u8 = if length > 4 {
      2
    } else if length > 2 {
      1
    } else {
      0
    };

    let mut query_parser = QueryParser::for_index(&self.index.clone(), vec![title_field]);
    query_parser.set_field_fuzzy(title_field, true, distance, true);
    let built_query = query_parser.parse_query(&query.clone()).unwrap();

    let searcher = self.index_reader.searcher();

    let mut search_results: Vec<SearchResultPB> = vec![];

    let top_docs = searcher.search(&built_query, &TopDocs::with_limit(10))?;

    // TODO: Score results by distance
    for (_score, doc_address) in top_docs {
      let retrieved_doc = searcher.doc(doc_address)?;

      let mut content = HashMap::new();
      let named_doc = self.folder_schema.schema.to_named_doc(&retrieved_doc);
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
}

impl IndexManager for FolderIndexManager {
  fn set_index_content_receiver(&self, mut rx: IndexContentReceiver) {
    let indexer = self.clone();
    af_spawn(async move {
      while let Ok(msg) = rx.recv().await {
        match msg {
          IndexContent::Create(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = indexer.add_index(IndexableData {
                id: view.id,
                data: view.name,
                icon: view.icon,
                layout: view.layout,
              });
            },
            Err(err) => tracing::error!("FolderIndexManager error deserialize: {:?}", err),
          },
          IndexContent::Update(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = indexer.update_index(IndexableData {
                id: view.id,
                data: view.name,
                icon: view.icon,
                layout: view.layout,
              });
            },
            Err(err) => tracing::error!("FolderIndexManager error deserialize: {:?}", err),
          },
          IndexContent::Delete(ids) => {
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

    let id_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_ID_FIELD_NAME)
      .unwrap();
    let title_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_TITLE_FIELD_NAME)
      .unwrap();
    let icon_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_ICON_FIELD_NAME)
      .unwrap();
    let icon_ty_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_ICON_TY_FIELD_NAME)
      .unwrap();

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
    ]);

    index_writer.commit()?;

    Ok(())
  }

  fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError> {
    let mut index_writer = self.get_index_writer()?;

    let id_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_ID_FIELD_NAME)
      .unwrap();

    for id in ids {
      let delete_term = Term::from_field_text(id_field, &id);
      index_writer.delete_term(delete_term);
    }

    index_writer.commit()?;

    Ok(())
  }

  fn add_index(&self, data: IndexableData) -> Result<(), FlowyError> {
    let mut index_writer = self.get_index_writer()?;

    let id_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_ID_FIELD_NAME)
      .unwrap();
    let title_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_TITLE_FIELD_NAME)
      .unwrap();
    let icon_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_ICON_FIELD_NAME)
      .unwrap();
    let icon_ty_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_ICON_TY_FIELD_NAME)
      .unwrap();

    let (icon, icon_ty) = self.extract_icon(data.icon, data.layout);

    // Add new index
    let _ = index_writer.add_document(doc![
      id_field => data.id,
      title_field => data.data,
      icon_field => icon.unwrap_or_default(),
      icon_ty_field => icon_ty,
    ]);

    index_writer.commit()?;

    Ok(())
  }

  fn as_any(&self) -> &dyn Any {
    self
  }
}
