use crate::errors::DocError;
use dashmap::DashMap;
use flowy_ot::{client::Document, core::Delta, errors::OTError};
use std::convert::TryInto;
use tokio::sync::RwLock;

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub struct DocId(pub(crate) String);

pub struct OpenDocument {
    document: Document,
}

impl<T> std::convert::From<T> for DocId
where
    T: ToString,
{
    fn from(s: T) -> Self { DocId(s.to_string()) }
}

pub(crate) struct OpenedDocumentCache {
    inner: DashMap<DocId, RwLock<OpenDocument>>,
}

impl OpenedDocumentCache {
    pub(crate) fn new() -> Self { Self { inner: DashMap::new() } }

    pub(crate) fn open<T, D>(&self, id: T, data: D) -> Result<(), DocError>
    where
        T: Into<DocId>,
        D: TryInto<Delta, Error = OTError>,
    {
        let doc_id = id.into();
        let delta = data.try_into()?;
        let document = Document::from_delta(delta);
        let doc_info = OpenDocument { document };
        self.inner.insert(doc_id, RwLock::new(doc_info));
        Ok(())
    }

    pub(crate) fn is_opened<T>(&self, id: T) -> bool
    where
        T: Into<DocId>,
    {
        let doc_id = id.into();
        self.inner.get(&doc_id).is_some()
    }

    pub(crate) async fn mut_doc<T, F>(&self, id: T, f: F) -> Result<(), DocError>
    where
        T: Into<DocId>,
        F: FnOnce(&mut Document) -> Result<(), DocError>,
    {
        let doc_id = id.into();
        match self.inner.get(&doc_id) {
            None => Err(doc_not_found()),
            Some(doc_info) => {
                let mut write_guard = doc_info.write().await;
                f(&mut write_guard.document)
            },
        }
    }

    pub(crate) async fn read_doc<T>(&self, id: T) -> Result<Vec<u8>, DocError>
    where
        T: Into<DocId> + Clone,
    {
        if self.is_opened(id.clone()) {
            return Err(doc_not_found());
        }

        let doc_id = id.into();
        let doc_info = self.inner.get(&doc_id).unwrap();
        let write_guard = doc_info.read().await;
        let doc = &(*write_guard).document;
        Ok(doc.to_bytes())
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

fn doc_not_found() -> DocError { DocError::not_found().context("Doc is close or you should call open first") }
