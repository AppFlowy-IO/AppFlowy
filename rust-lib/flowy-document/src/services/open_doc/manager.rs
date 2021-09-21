use crate::{
    errors::DocError,
    services::{
        open_doc::{DocId, OpenedDoc, OpenedDocPersistence},
        ws::WsManager,
    },
};
use bytes::Bytes;
use dashmap::DashMap;
use flowy_database::ConnectionPool;
use flowy_ot::{core::Delta, errors::OTError};
use parking_lot::RwLock;
use std::{convert::TryInto, fmt::Debug, sync::Arc};

pub(crate) struct OpenedDocManager {
    doc_map: DashMap<DocId, Arc<OpenedDoc>>,
    ws_manager: Arc<RwLock<WsManager>>,
    persistence: Arc<dyn OpenedDocPersistence>,
}

impl OpenedDocManager {
    pub(crate) fn new(ws_manager: Arc<RwLock<WsManager>>, persistence: Arc<dyn OpenedDocPersistence>) -> Self {
        Self {
            doc_map: DashMap::new(),
            ws_manager,
            persistence,
        }
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) fn open<T, D>(&self, id: T, data: D) -> Result<(), DocError>
    where
        T: Into<DocId> + Debug,
        D: TryInto<Delta, Error = OTError>,
    {
        let doc = Arc::new(OpenedDoc::new(
            id.into(),
            data.try_into()?,
            self.persistence.clone(),
            self.ws_manager.read().sender.clone(),
        ));
        self.ws_manager.write().register_handler(doc.id.as_ref(), doc.clone());
        self.doc_map.insert(doc.id.clone(), doc.clone());
        Ok(())
    }

    pub(crate) fn is_opened<T>(&self, id: T) -> bool
    where
        T: Into<DocId>,
    {
        let doc_id = id.into();
        self.doc_map.get(&doc_id).is_some()
    }

    #[tracing::instrument(level = "debug", skip(self, changeset, pool), err)]
    pub(crate) async fn apply_changeset<T>(&self, id: T, changeset: Bytes, pool: Arc<ConnectionPool>) -> Result<(), DocError>
    where
        T: Into<DocId> + Debug,
    {
        let id = id.into();
        match self.doc_map.get(&id) {
            None => Err(doc_not_found()),
            Some(doc) => {
                let _ = doc.apply_delta(changeset, pool)?;
                Ok(())
            },
        }
    }

    pub(crate) async fn read_doc<T>(&self, id: T) -> Result<Vec<u8>, DocError>
    where
        T: Into<DocId> + Clone,
    {
        if !self.is_opened(id.clone()) {
            return Err(doc_not_found());
        }

        let doc_id = id.into();
        let doc = self.doc_map.get(&doc_id).unwrap();
        Ok(doc.data())
    }

    pub(crate) fn close<T>(&self, id: T) -> Result<(), DocError>
    where
        T: Into<DocId>,
    {
        let doc_id = id.into();
        self.doc_map.remove(&doc_id);
        self.ws_manager.write().remove_handler(doc_id.as_ref());
        Ok(())
    }
}

fn doc_not_found() -> DocError { DocError::not_found().context("Doc is close or you should call open first") }
