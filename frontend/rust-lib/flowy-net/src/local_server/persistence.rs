use flowy_collaboration::{
    entities::{document_info::BlockInfo, folder_info::FolderInfo},
    errors::CollaborateError,
    protobuf::{RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB},
    server_document::*,
    server_folder::FolderCloudPersistence,
    util::{make_document_info_from_revisions_pb, make_folder_from_revisions_pb},
};
use lib_infra::future::BoxResultFuture;
use std::{
    fmt::{Debug, Formatter},
    sync::Arc,
};

// For the moment, we use memory to cache the data, it will be implemented with
// other storage. Like the Firestore,Dropbox.etc.
pub trait RevisionCloudStorage: Send + Sync {
    fn set_revisions(&self, repeated_revision: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError>;
    fn get_revisions(
        &self,
        object_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<RepeatedRevisionPB, CollaborateError>;

    fn reset_object(
        &self,
        object_id: &str,
        repeated_revision: RepeatedRevisionPB,
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
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<Option<FolderInfo>, CollaborateError> {
        let folder_id = folder_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision.clone()).await?;
            make_folder_from_revisions_pb(&folder_id, repeated_revision)
        })
    }

    fn save_folder_revisions(&self, repeated_revision: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError> {
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
    ) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        let folder_id = folder_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let mut repeated_revision = storage.get_revisions(&folder_id, rev_ids).await?;
            let revisions: Vec<RevisionPB> = repeated_revision.take_items().into();
            Ok(revisions)
        })
    }

    fn reset_folder(
        &self,
        folder_id: &str,
        repeated_revision: RepeatedRevisionPB,
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
    fn read_document(&self, doc_id: &str) -> BoxResultFuture<BlockInfo, CollaborateError> {
        let storage = self.storage.clone();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let repeated_revision = storage.get_revisions(&doc_id, None).await?;
            match make_document_info_from_revisions_pb(&doc_id, repeated_revision)? {
                Some(document_info) => Ok(document_info),
                None => Err(CollaborateError::record_not_found()),
            }
        })
    }

    fn create_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<Option<BlockInfo>, CollaborateError> {
        let doc_id = doc_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision.clone()).await?;
            make_document_info_from_revisions_pb(&doc_id, repeated_revision)
        })
    }

    fn read_document_revisions(
        &self,
        doc_id: &str,
        rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        let doc_id = doc_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let mut repeated_revision = storage.get_revisions(&doc_id, rev_ids).await?;
            let revisions: Vec<RevisionPB> = repeated_revision.take_items().into();
            Ok(revisions)
        })
    }

    fn save_document_revisions(&self, repeated_revision: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError> {
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision).await?;
            Ok(())
        })
    }

    fn reset_document(&self, doc_id: &str, revisions: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError> {
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
    fn set_revisions(&self, _repeated_revision: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError> {
        Box::pin(async move { Ok(()) })
    }

    fn get_revisions(
        &self,
        _doc_id: &str,
        _rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<RepeatedRevisionPB, CollaborateError> {
        Box::pin(async move {
            let repeated_revisions = RepeatedRevisionPB::new();
            Ok(repeated_revisions)
        })
    }

    fn reset_object(
        &self,
        _doc_id: &str,
        _repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<(), CollaborateError> {
        Box::pin(async move { Ok(()) })
    }
}
