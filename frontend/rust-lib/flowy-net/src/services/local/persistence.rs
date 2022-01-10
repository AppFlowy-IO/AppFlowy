use dashmap::DashMap;
use flowy_collaboration::{
    entities::doc::DocumentInfo,
    errors::CollaborateError,
    protobuf::{RepeatedRevision as RepeatedRevisionPB, Revision as RevisionPB},
    sync::*,
    util::repeated_revision_from_repeated_revision_pb,
};
use lib_infra::future::BoxResultFuture;
use std::{
    fmt::{Debug, Formatter},
    sync::Arc,
};

pub(crate) struct LocalServerDocumentPersistence {
    // For the moment, we use memory to cache the data, it will be implemented with other storage.
    // Like the Firestore,Dropbox.etc.
    inner: Arc<DashMap<String, DocumentInfo>>,
}

impl Debug for LocalServerDocumentPersistence {
    fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result { f.write_str("LocalDocServerPersistence") }
}

impl std::default::Default for LocalServerDocumentPersistence {
    fn default() -> Self {
        LocalServerDocumentPersistence {
            inner: Arc::new(DashMap::new()),
        }
    }
}

impl DocumentPersistence for LocalServerDocumentPersistence {
    fn read_document(&self, doc_id: &str) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let inner = self.inner.clone();
        let doc_id = doc_id.to_owned();
        Box::pin(async move {
            match inner.get(&doc_id) {
                None => Err(CollaborateError::record_not_found()),
                Some(val) => {
                    //
                    Ok(val.value().clone())
                },
            }
        })
    }

    fn create_document(
        &self,
        doc_id: &str,
        repeated_revision: RepeatedRevisionPB,
    ) -> BoxResultFuture<DocumentInfo, CollaborateError> {
        let doc_id = doc_id.to_owned();
        let inner = self.inner.clone();
        Box::pin(async move {
            let repeated_revision = repeated_revision_from_repeated_revision_pb(repeated_revision)?;
            let document_info = DocumentInfo::from_revisions(&doc_id, repeated_revision.into_inner())?;
            inner.insert(doc_id, document_info.clone());
            Ok(document_info)
        })
    }

    fn read_revisions(
        &self,
        _doc_id: &str,
        _rev_ids: Option<Vec<i64>>,
    ) -> BoxResultFuture<Vec<RevisionPB>, CollaborateError> {
        Box::pin(async move { Ok(vec![]) })
    }

    fn reset_document(&self, _doc_id: &str, _revisions: RepeatedRevisionPB) -> BoxResultFuture<(), CollaborateError> {
        unimplemented!()
    }
}
