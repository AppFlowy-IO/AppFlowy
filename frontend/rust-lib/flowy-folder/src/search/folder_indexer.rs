use std::sync::Arc;

use collab::core::collab::{IndexContent, IndexContentReceiver};
use collab_document::document::DocumentIndexContent;
use collab_folder::ViewIndexContent;
use flowy_error::FlowyError;
use lib_dispatch::prelude::af_spawn;
use lib_infra::async_trait::async_trait;
use tokio::task::spawn_blocking;
use tracing::error;

/// A trait for folder indexing storage.
pub trait FolderIndexStorage: Send + Sync {
  fn get_view_updated_at(&self, id: &str) -> Result<Option<i64>, FlowyError>;
  fn add_view(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn update_view(&self, id: &str, content: &str) -> Result<(), FlowyError>;
  fn remove_view(&self, ids: &[String]) -> Result<(), FlowyError>;
  fn add_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError>;
  fn update_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError>;
  fn remove_document(&self, page_ids: &[String]) -> Result<(), FlowyError>;
}

impl<T> FolderIndexStorage for Arc<T>
where
  T: FolderIndexStorage,
{
  fn get_view_updated_at(&self, id: &str) -> Result<Option<i64>, FlowyError> {
    (**self).get_view_updated_at(id)
  }

  fn add_view(&self, id: &str, content: &str) -> Result<(), FlowyError> {
    (**self).add_view(id, content)
  }

  fn update_view(&self, id: &str, content: &str) -> Result<(), FlowyError> {
    (**self).update_view(id, content)
  }

  fn remove_view(&self, ids: &[String]) -> Result<(), FlowyError> {
    (**self).remove_view(ids)
  }

  fn add_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError> {
    (**self).add_document(view_id, page_id, content)
  }

  fn update_document(&self, view_id: &str, page_id: &str, content: &str) -> Result<(), FlowyError> {
    (**self).update_document(view_id, page_id, content)
  }

  fn remove_document(&self, page_ids: &[String]) -> Result<(), FlowyError> {
    (**self).remove_document(page_ids)
  }
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

                  let add_view_storage = storage.clone();
                  let add_view_view = view.clone();
                  let add_view_handle = spawn_blocking(move || {
                    add_view_storage.add_view(&add_view_view.id, &add_view_view.name)
                  })
                  .await;

                  match add_view_handle {
                    Ok(res) => {
                      if let Err(e) = res {
                        error!("FolderIndexer error adding view: {:?}", e);
                        continue;
                      }
                    },
                    Err(e) => {
                      error!("FolderIndexer error adding view: {:?}", e);
                      continue;
                    },
                  }

                  let add_document_storage = storage.clone();
                  let add_document_view = view.clone();
                  let add_document_doc = doc.clone();
                  let add_document_handle = spawn_blocking(move || {
                    add_document_storage.add_document(
                      &add_document_view.id,
                      &add_document_doc.page_id,
                      &add_document_doc.text,
                    )
                  })
                  .await;

                  match add_document_handle {
                    Ok(res) => {
                      if let Err(e) = res {
                        error!("FolderIndexer error adding document: {:?}", e);
                        continue;
                      }
                    },
                    Err(e) => {
                      error!("FolderIndexer error adding document: {:?}", e);
                      continue;
                    },
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

                  let update_view_storage = storage.clone();
                  let update_view_view = view.clone();
                  let update_view_handle = spawn_blocking(move || {
                    update_view_storage.update_view(&update_view_view.id, &update_view_view.name)
                  })
                  .await;

                  match update_view_handle {
                    Ok(res) => {
                      if let Err(e) = res {
                        error!("FolderIndexer error updating view: {:?}", e);
                        continue;
                      }
                    },
                    Err(e) => {
                      error!("FolderIndexer error updating view: {:?}", e);
                      continue;
                    },
                  }

                  let update_document_storage = storage.clone();
                  let update_document_view = view.clone();
                  let update_document_doc = doc.clone();
                  let update_document_handle = spawn_blocking(move || {
                    update_document_storage.update_document(
                      &update_document_view.id,
                      &update_document_doc.page_id,
                      &update_document_doc.text,
                    )
                  })
                  .await;

                  match update_document_handle {
                    Ok(res) => {
                      if let Err(e) = res {
                        error!("FolderIndexer error updating document: {:?}", e);
                        continue;
                      }
                    },
                    Err(e) => {
                      error!("FolderIndexer error updating document: {:?}", e);
                      continue;
                    },
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
