use std::{any::Any, collections::HashMap, fs, path::Path, sync::Weak};

use crate::folder::schema::{FolderSchema, FOLDER_TITLE_FIELD_NAME};
use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::{timestamp, ViewIndexContent};
use flowy_error::{FlowyError, FlowyResult};
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_dispatch::prelude::af_spawn;
use tantivy::{
  collector::TopDocs, directory::MmapDirectory, doc, query::QueryParser, Index, IndexReader,
  IndexWriter, Term,
};

use crate::{
  entities::SearchResultPB,
  services::indexer::{IndexManager, IndexableData},
};

use super::{entities::FolderIndexData, schema::FOLDER_ID_FIELD_NAME};

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

    let top_docs = searcher.search(&built_query, &TopDocs::with_limit(10))?;
    let mut search_results: Vec<SearchResultPB> = vec![];
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
      search_results.push(result);
    }

    Ok(search_results)
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
              });
            },
            Err(err) => tracing::error!("FolderIndexManager error deserialize: {:?}", err),
          },
          IndexContent::Update(value) => match serde_json::from_value::<ViewIndexContent>(value) {
            Ok(view) => {
              let _ = indexer.update_index(IndexableData {
                id: view.id,
                data: view.name,
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

    let delete_term = Term::from_field_text(id_field, &data.id.clone());

    // Remove old index
    index_writer.delete_term(delete_term);

    // Add new index
    let _ = index_writer.add_document(doc![
      id_field => data.id.clone(),
      title_field => data.data,
    ]);

    tracing::warn!("Update Index: {:?} At({})", data.id.clone(), timestamp());
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

    // Add new index
    let _ = index_writer.add_document(doc![
      id_field => data.id,
      title_field => data.data,
    ]);

    index_writer.commit()?;

    Ok(())
  }

  fn as_any(&self) -> &dyn Any {
    self
  }
}
