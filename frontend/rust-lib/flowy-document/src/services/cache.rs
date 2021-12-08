use std::sync::Arc;

use dashmap::DashMap;

use crate::{
    errors::DocError,
    services::doc::edit::{ClientDocEditor, DocId},
};

pub(crate) struct DocCache {
    inner: DashMap<DocId, Arc<ClientDocEditor>>,
}

impl DocCache {
    pub(crate) fn new() -> Self { Self { inner: DashMap::new() } }

    #[allow(dead_code)]
    pub(crate) fn all_docs(&self) -> Vec<Arc<ClientDocEditor>> {
        self.inner
            .iter()
            .map(|kv| kv.value().clone())
            .collect::<Vec<Arc<ClientDocEditor>>>()
    }

    pub(crate) fn set(&self, doc: Arc<ClientDocEditor>) {
        let doc_id = doc.doc_id.clone();
        if self.inner.contains_key(&doc_id) {
            log::warn!("Doc:{} already exists in cache", &doc_id);
        }
        self.inner.insert(doc_id, doc);
    }

    pub(crate) fn contains(&self, doc_id: &str) -> bool { self.inner.get(doc_id).is_some() }

    pub(crate) fn get(&self, doc_id: &str) -> Result<Arc<ClientDocEditor>, DocError> {
        if !self.contains(&doc_id) {
            return Err(doc_not_found());
        }
        let opened_doc = self.inner.get(doc_id).unwrap();
        Ok(opened_doc.clone())
    }

    pub(crate) fn remove(&self, id: &str) {
        let doc_id: DocId = id.into();
        self.inner.remove(&doc_id);
    }
}

fn doc_not_found() -> DocError { DocError::doc_not_found().context("Doc is close or you should call open first") }
