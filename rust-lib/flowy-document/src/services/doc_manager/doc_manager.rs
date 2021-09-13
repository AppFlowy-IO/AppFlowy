use crate::errors::{DocError, ErrorBuilder, ErrorCode};
use dashmap::{mapref::one::Ref, DashMap};
use flowy_ot::{
    client::{Document, FlowyDoc},
    core::Delta,
};
use std::convert::TryInto;
use tokio::sync::RwLock;

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub struct DocId(pub(crate) String);

pub struct DocInfo {
    document: Document,
}

impl std::convert::From<String> for DocId {
    fn from(s: String) -> Self { DocId(s) }
}

pub(crate) struct DocManager {
    inner: DashMap<DocId, RwLock<DocInfo>>,
}

impl DocManager {
    pub(crate) fn new() -> Self { Self { inner: DashMap::new() } }
    pub(crate) fn open<T, D>(&self, id: T, data: D) -> Result<(), DocError>
    where
        T: Into<DocId>,
        D: TryInto<Delta, Error = DocError>,
    {
        let doc_id = id.into();
        let delta = data.try_into()?;
        let document = Document::from_delta(delta);
        let doc_info = DocInfo { document };
        self.inner.insert(doc_id, RwLock::new(doc_info));
        Ok(())
    }

    pub(crate) async fn mut_doc<T, F>(&self, id: T, f: F) -> Result<(), DocError>
    where
        T: Into<DocId>,
        F: FnOnce(&mut Document) -> Result<(), DocError>,
    {
        let doc_id = id.into();
        match self.inner.get(&doc_id) {
            None => Err(ErrorBuilder::new(ErrorCode::DocNotfound)
                .msg("Doc is close or you should call open first")
                .build()),
            Some(doc_info) => {
                let mut write_guard = doc_info.write().await;
                f(&mut write_guard.document)
            },
        }
    }

    pub(crate) fn close<T>(&self, id: T) -> Result<(), DocError>
    where
        T: Into<DocId>,
    {
        let doc_id = id.into();
        self.inner.remove(&doc_id);
        Ok(())
    }
}
