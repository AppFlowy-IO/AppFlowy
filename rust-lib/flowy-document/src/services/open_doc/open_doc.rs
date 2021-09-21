use crate::{
    entities::{
        doc::SaveDocParams,
        ws::{WsDocumentData, WsSource},
    },
    errors::DocError,
    services::ws::WsHandler,
};
use flowy_database::ConnectionPool;
use flowy_ot::{client::Document, core::Delta};
use parking_lot::RwLock;
use std::sync::Arc;

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
pub struct DocId(pub(crate) String);
impl AsRef<str> for DocId {
    fn as_ref(&self) -> &str { &self.0 }
}
impl<T> std::convert::From<T> for DocId
where
    T: ToString,
{
    fn from(s: T) -> Self { DocId(s.to_string()) }
}

pub(crate) trait OpenedDocPersistence: Send + Sync {
    fn save(&self, params: SaveDocParams, pool: Arc<ConnectionPool>) -> Result<(), DocError>;
}

pub(crate) struct OpenedDoc {
    pub(crate) id: DocId,
    document: RwLock<Document>,
    persistence: Arc<dyn OpenedDocPersistence>,
}

impl OpenedDoc {
    pub(crate) fn new(id: DocId, delta: Delta, persistence: Arc<dyn OpenedDocPersistence>) -> Self {
        Self {
            id,
            document: RwLock::new(Document::from_delta(delta)),
            persistence,
        }
    }

    pub(crate) fn data(&self) -> Vec<u8> { self.document.read().to_bytes() }

    pub(crate) fn apply_delta(&self, data: Vec<u8>, pool: Arc<ConnectionPool>) -> Result<(), DocError> {
        let mut write_guard = self.document.write();
        let _ = write_guard.apply_changeset(data)?;

        // Opti: strategy to save the document
        let mut save = SaveDocParams {
            id: self.id.0.clone(),
            data: write_guard.to_bytes(),
        };
        let _ = self.persistence.save(save, pool)?;

        Ok(())
    }
}

impl WsHandler for OpenedDoc {
    fn receive(&self, data: WsDocumentData) {
        match data.source {
            WsSource::Delta => {},
        }
    }
}
