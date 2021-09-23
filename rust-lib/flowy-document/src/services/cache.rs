use std::sync::Arc;

use dashmap::DashMap;

use crate::{
    errors::DocError,
    services::doc::edit_context::{DocId, EditDocContext},
};

pub(crate) struct DocCache {
    inner: DashMap<DocId, Arc<EditDocContext>>,
}

impl DocCache {
    pub(crate) fn new() -> Self { Self { inner: DashMap::new() } }

    pub(crate) fn set(&self, doc: Arc<EditDocContext>) {
        let doc_id = doc.id.clone();
        if self.inner.contains_key(&doc_id) {
            log::warn!("Doc:{} already exists in cache", doc_id.as_ref());
        }
        self.inner.insert(doc.id.clone(), doc);
    }

    pub(crate) fn is_opened(&self, doc_id: &str) -> bool {
        let doc_id: DocId = doc_id.into();
        self.inner.get(&doc_id).is_some()
    }

    pub(crate) fn get(&self, doc_id: &str) -> Result<Arc<EditDocContext>, DocError> {
        if !self.is_opened(&doc_id) {
            return Err(doc_not_found());
        }
        let doc_id: DocId = doc_id.into();
        let opened_doc = self.inner.get(&doc_id).unwrap();
        Ok(opened_doc.clone())
    }

    pub(crate) fn remove(&self, id: &str) {
        let doc_id: DocId = id.into();
        self.inner.remove(&doc_id);
    }
}

fn doc_not_found() -> DocError { DocError::not_found().context("Doc is close or you should call open first") }
