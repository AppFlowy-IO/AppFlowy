use std::{any::Any, fs, path::Path, sync::Weak};

use crate::folder::schema::{FolderSchema, FOLDER_TITLE_FIELD_NAME};
use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::ViewIndexContent;
use flowy_error::FlowyError;
use flowy_user::services::authenticate_user::AuthenticateUser;
use lib_dispatch::prelude::af_spawn;
use tantivy::{
  collector::TopDocs, directory::MmapDirectory, doc, query::QueryParser, DocAddress, Index, Score,
  Term,
};

use crate::{
  entities::SearchResultPB,
  services::indexer::{IndexManager, IndexableData},
};

use super::schema::FOLDER_ID_FIELD_NAME;

#[derive(Clone)]
pub struct FolderIndexManager {
  folder_schema: FolderSchema,
  index: Index,
}

const FOLDER_INDEX_DIR: &str = "folder_index";

impl FolderIndexManager {
  pub fn new(auth_user: Weak<AuthenticateUser>) -> Self {
    let authenticate_user = auth_user.upgrade();
    let storage_path = match authenticate_user {
      Some(authenticate_user) => authenticate_user.get_index_path(),
      None => {
        panic!("The user is not available");
      },
    };

    let index_path = storage_path.join(Path::new(FOLDER_INDEX_DIR));

    if !index_path.exists() {
      let _ = fs::create_dir_all(&index_path);
    }

    let dir = MmapDirectory::open(index_path);
    let folder_schema = FolderSchema::new();

    let dir = match dir {
      Ok(dir) => dir,
      Err(err) => {
        panic!("Failed to open folder index directory: {:?}", err)
      },
    };

    let index = Index::open_or_create(dir, folder_schema.clone().schema).unwrap();

    Self {
      folder_schema,
      index,
    }
  }

  pub fn search(&self, query: String) -> Result<Vec<SearchResultPB>, FlowyError> {
    let title_field = self
      .folder_schema
      .schema
      .get_field(FOLDER_TITLE_FIELD_NAME)
      .unwrap();

    let mut query_parser = QueryParser::for_index(&self.index.clone(), vec![title_field]);
    query_parser.set_field_fuzzy(title_field, true, 2, true);
    let built_query = query_parser.parse_query(&query.clone()).unwrap();

    let reader = self.index.reader().unwrap();
    let searcher = reader.searcher();

    let top_docs: Vec<(Score, DocAddress)> = searcher
      .search(&built_query, &TopDocs::with_limit(10))
      .unwrap();

    for (_score, doc_address) in top_docs {
      let retrieved_doc = searcher.doc(doc_address).unwrap();
      println!("{}", self.folder_schema.schema.to_json(&retrieved_doc));
    }

    Ok(vec![])
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
    let mut index_writer = self.index.writer(50000000).unwrap();

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
    id_field => data.id,
    title_field => data.data,
    ]);

    index_writer.commit()?;

    Ok(())
  }

  fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError> {
    let mut index_writer = self.index.writer(50000000).unwrap();
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
    let mut index_writer = self.index.writer(50000000).unwrap();

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
