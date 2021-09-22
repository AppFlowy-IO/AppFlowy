use crate::{
    entities::doc::Doc,
    errors::DocError,
    services::{
        open_doc::{DocId, OpenedDoc},
        ws::WsManager,
    },
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_ot::{core::Delta, errors::OTError};
use parking_lot::RwLock;
use std::{convert::TryInto, fmt::Debug, sync::Arc};

pub(crate) struct DocCache {
    doc_map: DashMap<DocId, Arc<OpenedDoc>>,
}

impl DocCache {
    pub(crate) fn new() -> Self { Self { doc_map: DashMap::new() } }

    pub(crate) fn set(&self, doc: Arc<OpenedDoc>) -> Result<(), DocError> {
        self.doc_map.insert(doc.id.clone(), doc);
        Ok(())
    }

    pub(crate) fn is_opened(&self, doc_id: &str) -> bool {
        let doc_id: DocId = doc_id.into();
        self.doc_map.get(&doc_id).is_some()
    }

    pub(crate) fn get(&self, doc_id: &str) -> Result<Arc<OpenedDoc>, DocError> {
        if !self.is_opened(&doc_id) {
            return Err(doc_not_found());
        }
        let doc_id: DocId = doc_id.into();
        let opened_doc = self.doc_map.get(&doc_id).unwrap();
        Ok(opened_doc.clone())
    }

    pub(crate) fn remove(&self, id: &str) {
        let doc_id: DocId = id.into();
        self.doc_map.remove(&doc_id);
    }
}

fn doc_not_found() -> DocError { DocError::not_found().context("Doc is close or you should call open first") }
