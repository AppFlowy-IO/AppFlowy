use document_model::document::DocumentInfo;
use flowy_client_sync::{errors::SyncError, util::make_document_info_from_revisions};
use flowy_server_sync::server_folder::make_folder_from_revisions;
use flowy_sync::ext::{DocumentCloudPersistence, FolderCloudPersistence};
use folder_model::folder::FolderInfo;
use lib_infra::future::BoxResultFuture;
use revision_model::Revision;
use std::{
  fmt::{Debug, Formatter},
  sync::Arc,
};

// For the moment, we use memory to cache the data, it will be implemented with
// other storage. Like the Firestore,Dropbox.etc.
pub trait RevisionCloudStorage: Send + Sync {
  fn set_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError>;
  fn get_revisions(
    &self,
    object_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError>;
  fn reset_object(
    &self,
    object_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError>;
}

pub(crate) struct LocalDocumentCloudPersistence {
  storage: Arc<dyn RevisionCloudStorage>,
}

impl Debug for LocalDocumentCloudPersistence {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    f.write_str("LocalRevisionCloudPersistence")
  }
}

impl std::default::Default for LocalDocumentCloudPersistence {
  fn default() -> Self {
    LocalDocumentCloudPersistence {
      storage: Arc::new(MemoryDocumentCloudStorage::default()),
    }
  }
}

impl FolderCloudPersistence for LocalDocumentCloudPersistence {
  fn read_folder(&self, _user_id: &str, folder_id: &str) -> BoxResultFuture<FolderInfo, SyncError> {
    let storage = self.storage.clone();
    let folder_id = folder_id.to_owned();
    Box::pin(async move {
      let revisions = storage.get_revisions(&folder_id, None).await?;
      match make_folder_from_revisions(&folder_id, revisions)? {
        Some(folder_info) => Ok(folder_info),
        None => Err(SyncError::record_not_found()),
      }
    })
  }

  fn create_folder(
    &self,
    _user_id: &str,
    folder_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<Option<FolderInfo>, SyncError> {
    let folder_id = folder_id.to_owned();
    let storage = self.storage.clone();
    Box::pin(async move {
      storage.set_revisions(revisions.clone()).await?;
      make_folder_from_revisions(&folder_id, revisions)
    })
  }

  fn save_folder_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError> {
    let storage = self.storage.clone();
    Box::pin(async move {
      storage.set_revisions(revisions).await?;
      Ok(())
    })
  }

  fn read_folder_revisions(
    &self,
    folder_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError> {
    let folder_id = folder_id.to_owned();
    let storage = self.storage.clone();
    Box::pin(async move { storage.get_revisions(&folder_id, rev_ids).await })
  }

  fn reset_folder(
    &self,
    folder_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError> {
    let storage = self.storage.clone();
    let folder_id = folder_id.to_owned();
    Box::pin(async move {
      storage.reset_object(&folder_id, revisions).await?;
      Ok(())
    })
  }
}

impl DocumentCloudPersistence for LocalDocumentCloudPersistence {
  fn read_document(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, SyncError> {
    let storage = self.storage.clone();
    let doc_id = doc_id.to_owned();
    Box::pin(async move {
      let repeated_revision = storage.get_revisions(&doc_id, None).await?;
      match make_document_info_from_revisions(&doc_id, repeated_revision)? {
        Some(document_info) => Ok(document_info),
        None => Err(SyncError::record_not_found()),
      }
    })
  }

  fn create_document(
    &self,
    doc_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<Option<DocumentInfo>, SyncError> {
    let doc_id = doc_id.to_owned();
    let storage = self.storage.clone();
    Box::pin(async move {
      storage.set_revisions(revisions.clone()).await?;
      make_document_info_from_revisions(&doc_id, revisions)
    })
  }

  fn read_document_revisions(
    &self,
    doc_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError> {
    let doc_id = doc_id.to_owned();
    let storage = self.storage.clone();
    Box::pin(async move { storage.get_revisions(&doc_id, rev_ids).await })
  }

  fn save_document_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError> {
    let storage = self.storage.clone();
    Box::pin(async move {
      storage.set_revisions(revisions).await?;
      Ok(())
    })
  }

  fn reset_document(
    &self,
    doc_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError> {
    let storage = self.storage.clone();
    let doc_id = doc_id.to_owned();
    Box::pin(async move {
      storage.reset_object(&doc_id, revisions).await?;
      Ok(())
    })
  }
}

#[derive(Default)]
struct MemoryDocumentCloudStorage {}
impl RevisionCloudStorage for MemoryDocumentCloudStorage {
  fn set_revisions(&self, _revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError> {
    Box::pin(async move { Ok(()) })
  }

  fn get_revisions(
    &self,
    _object_id: &str,
    _rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError> {
    Box::pin(async move { Ok(vec![]) })
  }

  fn reset_object(
    &self,
    _object_id: &str,
    _revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError> {
    Box::pin(async move { Ok(()) })
  }
}
