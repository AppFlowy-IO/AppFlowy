use flowy_collaboration::{
    entities::doc::DocumentInfo,
    errors::CollaborateError,
    protobuf::{RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB},
    server_document::*,
    util::{make_doc_from_revisions, repeated_revision_from_repeated_revision_pb},
};
use lib_infra::future::BoxResultFuture;
use std::{
    convert::TryInto,
    fmt::{Debug, Formatter},
    sync::Arc,
};

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
    // For the moment, we use memory to cache the data, it will be implemented with other storage.
    // Like the Firestore,Dropbox.etc.
    storage: Arc<dyn RevisionCloudStorage>,
}

impl Debug for LocalDocumentCloudPersistence {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str("LocalRevisionCloudPersistence") }
}

impl std::default::Default for LocalDocumentCloudPersistence {
    fn default() -> Self {
        LocalDocumentCloudPersistence {
            storage: Arc::new(MemoryDocumentCloudStorage::default()),
        }
    }
}

impl DocumentCloudPersistence for LocalDocumentCloudPersistence {
    fn read_document(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let storage = self.storage.clone();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            let repeated_revision = storage.get_revisions(&doc_id, None).await?;
            match make_doc_from_revisions(&doc_id, repeated_revision) {
                Ok(Some(mut document_info_pb)) => {
                    let document_info: DocumentInfo = (&mut document_info_pb)
                        .try_into()
                        .map_err(|e| CollaborateError::internal().context(e))?;
                    Ok(document_info)
                },
                Ok(None) => Err(CollaborateError::record_not_found()),
                Err(e) => Err(CollaborateError::internal().context(e)),
            }
        })
    }

    fn create_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let doc_id = doc_id.to_owned();
        let storage = self.storage.clone();
        Box::pin(async move {
            let _ = storage.set_revisions(repeated_revision.clone()).await?;
            let repeated_revision = repeated_revision_from_repeated_revision_pb(repeated_revision)?;
            let document_info = DocumentInfo::from_revisions(&doc_id, repeated_revision.into_inner())?;
            Ok(document_info)
        })
    }

    fn read_revisions(
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

    fn save_revisions(&self, repeated_revision: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError> {
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

struct MemoryDocumentCloudStorage {}
impl std::default::Default for MemoryDocumentCloudStorage {
    fn default() -> Self { Self {} }
}
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
