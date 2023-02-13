use crate::errors::SyncError;
use crate::RevisionSyncPersistence;
use document_model::document::DocumentInfo;
use folder_model::FolderInfo;
use lib_infra::future::BoxResultFuture;
use revision_model::Revision;
use std::fmt::Debug;
use std::sync::Arc;

pub trait FolderCloudPersistence: Send + Sync + Debug {
  fn read_folder(&self, user_id: &str, folder_id: &str) -> BoxResultFuture<FolderInfo, SyncError>;

  fn create_folder(
    &self,
    user_id: &str,
    folder_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<Option<FolderInfo>, SyncError>;

  fn save_folder_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError>;

  fn read_folder_revisions(
    &self,
    folder_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError>;

  fn reset_folder(
    &self,
    folder_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError>;
}

impl RevisionSyncPersistence for Arc<dyn FolderCloudPersistence> {
  fn read_revisions(
    &self,
    object_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError> {
    (**self).read_folder_revisions(object_id, rev_ids)
  }

  fn save_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError> {
    (**self).save_folder_revisions(revisions)
  }

  fn reset_object(
    &self,
    object_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError> {
    (**self).reset_folder(object_id, revisions)
  }
}

pub trait DocumentCloudPersistence: Send + Sync + Debug {
  fn read_document(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, SyncError>;

  fn create_document(
    &self,
    doc_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<Option<DocumentInfo>, SyncError>;

  fn read_document_revisions(
    &self,
    doc_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError>;

  fn save_document_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError>;

  fn reset_document(
    &self,
    doc_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError>;
}

impl RevisionSyncPersistence for Arc<dyn DocumentCloudPersistence> {
  fn read_revisions(
    &self,
    object_id: &str,
    rev_ids: Option<Vec<i64>>,
  ) -> BoxResultFuture<Vec<Revision>, SyncError> {
    (**self).read_document_revisions(object_id, rev_ids)
  }

  fn save_revisions(&self, revisions: Vec<Revision>) -> BoxResultFuture<(), SyncError> {
    (**self).save_document_revisions(revisions)
  }

  fn reset_object(
    &self,
    object_id: &str,
    revisions: Vec<Revision>,
  ) -> BoxResultFuture<(), SyncError> {
    (**self).reset_document(object_id, revisions)
  }
}
