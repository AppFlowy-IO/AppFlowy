use flowy_sync::entities::revision::{RepeatedRevision, Revision};
use flowy_sync::{
    entities::{document::DocumentPayloadPB, folder::FolderInfo},
    errors::CollaborateError,
    server_document::*,
    server_folder::FolderCloudPersistence,
    util::{make_document_from_revision_pbs, make_folder_from_revisions_pb},
};
use lib_infra::future::BoxResultFuture;
use std::{
    fmt::{Debug, Formatter},
    sync::Arc,
};

// For the moment, we use memory to cache the data, it will be implemented with
// other storage. Like the Firestore,Dropbox.etc.
pub trait RevisionCloudStorage: Send + Sync {
    fn set_revisions(&self, repeated_revision: RepeatedRevision) -> BoxResultFuture<(), CollaborateError>;
    fn get_revisions(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<RepeatedRevision, CollaborateError>;

    fn reset_object(
        &self,
        object_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<(), CollaborateError>;
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
    fn read_folder(&self, _user_id: &str, folder_id: &str) -> BoxResultFuture<FolderInfo, CollaborateError> {
        let storage = self.storage.clone();
        let folder_id = folder_id.to_owned();
        Box::pin(async move {
            let repeated_revision = storage.get_revisions(&folder_id, None).await?;
            match make_folder_from_revisions_pb(&folder_id, repeated_revision)? {
                Some(folder_info) => Ok(folder_info),
                None => Err(CollaborateError::record_not_found()),
            }
        })
    }

    fn create_folder(
        &self,
        _user_id: &str,
        folder_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<Option<FolderInfo>, CollaborateError> {
        let folder_id = folder_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision.clone()).await?;
            make_folder_from_revisions_pb(&folder_id, repeated_revision)
        })
    }

    fn save_folder_revisions(&self, repeated_revision: RepeatedRevision) -> BoxResultFuture<(), CollaborateError> {
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision).await?;
            Ok(())
        })
    }

    fn read_folder_revisions(
        &self,
        folder_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<Revision>, CollaborateError> {
        let folder_id = folder_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let repeated_revision = storage.get_revisions(&folder_id, rev_ids).await?;
            Ok(repeated_revision.into_inner())
        })
    }

    fn reset_folder(
        &self,
        folder_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<(), CollaborateError> {
        let storage = self.storage.clone();
        let folder_id = folder_id.to_owned();
        Box::pin(async move {
            let _ = storage.reset_object(&folder_id, repeated_revision).await?;
            Ok(())
        })
    }
}

impl DocumentCloudPersistence for LocalDocumentCloudPersistence {
    fn read_document(&self, doc_id: &str) -> BoxResultFuture<DocumentPayloadPB, CollaborateError> {
        let storage = self.storage.clone();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let repeated_revision = storage.get_revisions(&doc_id, None).await?;
            match make_document_from_revision_pbs(&doc_id, repeated_revision)? {
                Some(document_info) => Ok(document_info),
                None => Err(CollaborateError::record_not_found()),
            }
        })
    }

    fn create_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<Option<DocumentPayloadPB>, CollaborateError> {
        let doc_id = doc_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision.clone()).await?;
            make_document_from_revision_pbs(&doc_id, repeated_revision)
        })
    }

    fn read_document_revisions(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<Revision>, CollaborateError> {
        let doc_id = doc_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let repeated_revision = storage.get_revisions(&doc_id, rev_ids).await?;
            Ok(repeated_revision.into_inner())
        })
    }

    fn save_document_revisions(&self, repeated_revision: RepeatedRevision) -> BoxResultFuture<(), CollaborateError> {
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision).await?;
            Ok(())
        })
    }

    fn reset_document(&self, doc_id: &str, revisions: RepeatedRevision) -> BoxResultFuture<(), CollaborateError> {
        let storage = self.storage.clone();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let _ = storage.reset_object(&doc_id, revisions).await?;
            Ok(())
        })
    }
}

#[derive(Default)]
struct MemoryDocumentCloudStorage {}
impl RevisionCloudStorage for MemoryDocumentCloudStorage {
    fn set_revisions(&self, _repeated_revision: RepeatedRevision) -> BoxResultFuture<(), CollaborateError> {
        Box::pin(async move { Ok(()) })
    }

    fn get_revisions(
        &self,
        _doc_id: &str,
        _rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<RepeatedRevision, CollaborateError> {
        Box::pin(async move {
            let repeated_revisions = RepeatedRevision::default();
            Ok(repeated_revisions)
        })
    }

    fn reset_object(
        &self,
        _doc_id: &str,
        _repeated_revision: RepeatedRevision,
    ) -> BoxResultFuture<(), CollaborateError> {
        Box::pin(async move { Ok(()) })
    }
}
