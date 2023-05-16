use std::{
  fmt::{Debug, Formatter},
  sync::Arc,
};

use lib_infra::future::BoxResultFuture;
use revision_model::Revision;

// For the moment, we use memory to cache the data, it will be implemented with
// other storage. Like the Firestore,Dropbox.etc.
pub trait RevisionCloudStorage: Send + Sync {
  fn set_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), String>;
  fn get_revisions(
    &self,
    object_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, String>;
  fn reset_object(&self, object_id: &str, revisions: Vec<Revision>) -> BoxResultFuture<(), String>;
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
//
// impl FolderCloudPersistence for LocalDocumentCloudPersistence {
//   fn read_folder(&self, _user_id: &str, _folder_id: &str) -> BoxResultFuture<String, SyncError> {
//     todo!()
//     // let storage = self.storage.clone();
//     // let folder_id = folder_id.to_owned();
//     // Box::pin(async move {
//     //   let revisions = storage.get_revisions(&folder_id, None).await?;
//     //   match make_folder_from_revisions(&folder_id, revisions)? {
//     //     Some(folder_info) => Ok(folder_info),
//     //     None => Err(SyncError::record_not_found()),
//     //   }
//     // })
//   }
//
//   fn create_folder(
//     &self,
//     _user_id: &str,
//     _folder_id: &str,
//     _revisions: Vec<Revision>,
//   ) -> BoxResultFuture<Option<String>, SyncError> {
//     todo!()
//   }
//
//   fn save_folder_revisions(&self, _revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError> {
//     todo!()
//   }
//
//   fn read_folder_revisions(
//     &self,
//     _folder_id: &str,
//     _rev_ids: Option<Vec<i64>>,
//   ) -> BoxResultFuture<Vec<Revision>, SyncError> {
//     todo!()
//   }
//
//   fn reset_folder(
//     &self,
//     _folder_id: &str,
//     _revisions: Vec<Revision>,
//   ) -> BoxResultFuture<(), SyncError> {
//     todo!()
//   }
// }
//
// impl DocumentCloudPersistence for LocalDocumentCloudPersistence {
//   fn read_document(&self, _doc_id: &str) -> BoxResultFuture<DocumentInfo, SyncError> {
//     todo!()
//   }
//
//   fn create_document(
//     &self,
//     _doc_id: &str,
//     _revisions: Vec<Revision>,
//   ) -> BoxResultFuture<Option<DocumentInfo>, SyncError> {
//     todo!()
//   }
//
//   fn read_document_revisions(
//     &self,
//     _doc_id: &str,
//     _rev_ids: Option<Vec<i64>>,
//   ) -> BoxResultFuture<Vec<Revision>, SyncError> {
//     todo!()
//   }
//
//   fn save_document_revisions(&self, _revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError> {
//     todo!()
//   }
//
//   fn reset_document(
//     &self,
//     _doc_id: &str,
//     _revisions: Vec<Revision>,
//   ) -> BoxResultFuture<(), SyncError> {
//     todo!()
//   }
// }

#[derive(Default)]
struct MemoryDocumentCloudStorage {}
impl RevisionCloudStorage for MemoryDocumentCloudStorage {
  fn set_revisions(&self, _revisions: Vec<Revision>) -> BoxResultFuture<(), String> {
    Box::pin(async move { Ok(()) })
  }

  fn get_revisions(
    &self,
    _object_id: &str,
    _rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, String> {
    Box::pin(async move { Ok(vec![]) })
  }

  fn reset_object(
    &self,
    _object_id: &str,
    _revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), String> {
    Box::pin(async move { Ok(()) })
  }
}
