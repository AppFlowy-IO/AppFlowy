use std::sync::Arc;

use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_document::document::DocumentIndexContent;
use collab_folder::ViewIndexContent;
use flowy_error::FlowyError;
use flowy_folder_pub::entities::SearchData;
use lib_dispatch::prelude::af_spawn;
use lib_infra::async_trait::async_trait;
use tracing::error;

/// A trait for folder indexing storage.
pub trait FolderIndexStorage: Send + Sync {
  fn search(&self, s: &str, limit: Option<i64>) -> Result<Vec<SearchData>, FlowyError>;
  fn add_view(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn update_view(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn remove_view(&self, ids: &[String]) -> Result<(), FlowyError>;
  fn add_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError>;
  fn update_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError>;
  fn remove_document(&self, page_ids: &[String]) -> Result<(), FlowyError>;
}

#[async_trait]
pub trait DocumentIndexContentGetter: Send + Sync {
  async fn get_document_index_content(
    &self,
    doc_id: &str,
  ) -> Result<DocumentIndexContent, FlowyError>;
}

pub struct FolderIndexer {
  storage: Arc<dyn FolderIndexStorage>,
  document_index_content_getter: Arc<dyn DocumentIndexContentGetter>,
}

impl FolderIndexer {
  pub fn new<S, D>(storage: S, doc_getter: D) -> Self
  where
    S: FolderIndexStorage + 'static,
    D: DocumentIndexContentGetter + 'static,
  {
    Self {
      storage: Arc::new(storage),
      document_index_content_getter: Arc::new(doc_getter),
    }
  }

  pub fn search(&self, s: &str, limit: Option<i64>) -> Result<Vec<SearchData>, FlowyError> {
    self.storage.search(s, limit)
  }

  pub fn set_index_content_receiver(&self, mut rx: IndexContentReceiver) {
    let weak_storage = Arc::downgrade(&self.storage);
    let document_index_content_getter = Arc::clone(&self.document_index_content_getter);
    af_spawn(async move {
      while let Ok(msg) = rx.recv().await {
        if let Some(storage) = weak_storage.upgrade() {
          match msg {
            IndexContent::Create(value) => {
              match serde_json::from_value::<ViewIndexContent>(value) {
                Ok(view) => {
                  let doc = match document_index_content_getter
                    .get_document_index_content(&view.id)
                    .await
                  {
                    Ok(doc) => doc,
                    Err(e) => {
                      error!("FolderIndexer error getting document: {:?}", e);
                      continue;
                    },
                  };

                  if let Err(e) = storage.add_view(&view.id, &view.name) {
                    error!("FolderIndexer error adding view: {:?}", e);
                    continue;
                  }

                  if let Err(e) = storage.add_document(&view.id, &doc.page_id, &doc.text) {
                    error!("FolderIndexer error adding document: {:?}", e);
                    continue;
                  }
                },
                Err(err) => error!("FolderIndexer error deserialize: {:?}", err),
              }
            },
            IndexContent::Update(value) => {
              match serde_json::from_value::<ViewIndexContent>(value) {
                Ok(view) => {
                  let doc = match document_index_content_getter
                    .get_document_index_content(&view.id)
                    .await
                  {
                    Ok(doc) => doc,
                    Err(e) => {
                      error!("FolderIndexer error getting document: {:?}", e);
                      continue;
                    },
                  };

                  if let Err(e) = storage.update_view(&view.id, &view.name) {
                    error!("FolderIndexer error updating view: {:?}", e);
                    continue;
                  }

                  if let Err(e) = storage.update_document(&view.id, &doc.page_id, &doc.text) {
                    error!("FolderIndexer error updating document: {:?}", e);
                    continue;
                  }
                },
                Err(err) => error!("FolderIndexer error deserialize: {:?}", err),
              }
            },
            IndexContent::Delete(ids) => {
              if let Err(e) = storage.remove_view(&ids) {
                error!("FolderIndexer error deserialize: {:?}", e);
              }
            },
          }
        }
      }
    });
  }
}
