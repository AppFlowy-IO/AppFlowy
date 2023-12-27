use std::sync::Arc;

use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_folder::ViewIndexContent;
use flowy_error::FlowyError;
use lib_dispatch::prelude::af_spawn;
use tracing::error;

/// A trait for folder indexing storage.
pub trait FolderIndexStorage: Send + Sync {
  fn add(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn update(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn remove(&self, ids: &[String]) -> Result<(), FlowyError>;
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

  pub fn set_index_content_receiver(&self, mut rx: IndexContentReceiver) {
    let weak_storage = Arc::downgrade(&self.storage);
    af_spawn(async move {
      while let Ok(msg) = rx.recv().await {
        if let Some(storage) = weak_storage.upgrade() {
          match msg {
            IndexContent::Create(value) => {
              match serde_json::from_value::<ViewIndexContent>(value) {
                Ok(view) => {
                  if let Err(e) = storage.add(&view.id, &view.name) {
                    error!("FolderIndexer error adding index: {:?}", e)
                  }
                },
                Err(err) => error!("FolderIndexer error deserialize: {:?}", err),
              }
            },
            IndexContent::Update(value) => {
              match serde_json::from_value::<ViewIndexContent>(value) {
                Ok(view) => {
                  if let Err(e) = storage.update(&view.id, &view.name) {
                    error!("FolderIndexer error adding index: {:?}", e)
                  }
                },
                Err(err) => error!("FolderIndexer error deserialize: {:?}", err),
              }
            },
            IndexContent::Delete(ids) => {
              if let Err(e) = storage.remove(&ids) {
                error!("FolderIndexer error deserialize: {:?}", e);
              }
            },
          }
        }
      }
    });
  }
}
