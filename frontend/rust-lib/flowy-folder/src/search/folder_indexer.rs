use std::sync::Arc;

use collab::core::collab::IndexContentReceiver;

use lib_dispatch::prelude::af_spawn;

/// A trait for folder indexing storage.
pub trait FolderIndexStorage: Send + Sync {
  fn add(&self, id: &str, content: &str);
  fn remove(&self, id: &str);
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
      while let Ok(value) = rx.recv().await {
        if let Some(storage) = weak_storage.upgrade() {
          // do something with storage
        }
      }
    });
  }
}
