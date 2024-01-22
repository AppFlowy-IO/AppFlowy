use std::sync::Arc;

use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_document::document::DocumentIndexContent;
use collab_folder::ViewIndexContent;
use flowy_error::FlowyError;
use flowy_folder_deps::entities::SearchData;
use lib_dispatch::prelude::af_spawn;
use lib_infra::async_trait::async_trait;
use tracing::error;

/// A trait for folder indexing storage.
pub trait FolderIndexStorage: Send + Sync {
  fn search(&self, s: &str, limit: Option<i64>) -> Result<Vec<SearchData>, FlowyError>;
  fn add_view(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn update_view(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn remove_view(&self, ids: &[String]) -> Result<(), FlowyError>;
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
}

impl FolderIndexer {
  pub fn new<S>(storage: S) -> Self
  where
    S: FolderIndexStorage + 'static,
  {
    Self {
      storage: Arc::new(storage),
    }
  }

  pub fn search(&self, s: &str, limit: Option<i64>) -> Result<Vec<SearchData>, FlowyError> {
    self.storage.search(s, limit)
  }

  pub fn set_index_content_receiver(&self, mut rx: IndexContentReceiver) {
    let weak_storage = Arc::downgrade(&self.storage);
    af_spawn(async move {
      while let Ok(msg) = rx.recv().await {
        if let Some(storage) = weak_storage.upgrade() {
          match msg {
            IndexContent::Create(value) => {
              match serde_json::from_value::<ViewIndexContent>(value) {
                Ok(view) => {
                  if let Err(e) = storage.add_view(&view.id, &view.name) {
                    error!("FolderIndexer error adding view: {:?}", e);
                    continue;
                  }
                },
                Err(err) => error!("FolderIndexer error deserialize: {:?}", err),
              }
            },
            IndexContent::Update(value) => {
              match serde_json::from_value::<ViewIndexContent>(value) {
                Ok(view) => {
                  if let Err(e) = storage.update_view(&view.id, &view.name) {
                    error!("FolderIndexer error updating view: {:?}", e);
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
