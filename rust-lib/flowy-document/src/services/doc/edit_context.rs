use crate::{
    entities::{
        doc::{Doc, UpdateDocParams},
        ws::{WsDocumentData, WsSource},
    },
    errors::DocError,
    services::{
        doc::Document,
        ws::{WsHandler, WsSender},
    },
    sql_tables::doc::OpTableSql,
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_ot::core::Delta;
use parking_lot::RwLock;
use std::{convert::TryInto, sync::Arc};

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

pub(crate) trait EditDocPersistence: Send + Sync {
    fn save(&self, params: UpdateDocParams, pool: Arc<ConnectionPool>) -> Result<(), DocError>;
}

pub(crate) struct EditDocContext {
    pub(crate) id: DocId,
    pub(crate) revision: i64,
    document: RwLock<Document>,
    ws_sender: Arc<dyn WsSender>,
    op_sql: Arc<OpTableSql>,
}

impl EditDocContext {
    pub(crate) fn new(doc: Doc, ws_sender: Arc<dyn WsSender>, op_sql: Arc<OpTableSql>) -> Result<Self, DocError> {
        let id: DocId = doc.id.into();
        let revision = doc.revision;
        let delta: Delta = doc.data.try_into()?;
        let document = RwLock::new(Document::from_delta(delta));

        Ok(Self {
            id,
            revision,
            document,
            ws_sender,
            op_sql,
        })
    }

    pub(crate) fn doc(&self) -> Doc {
        Doc {
            id: self.id.0.clone(),
            data: self.document.read().to_bytes(),
            revision: self.revision,
        }
    }

    pub(crate) fn apply_delta(&self, data: Bytes, pool: Arc<ConnectionPool>) -> Result<(), DocError> {
        let mut write_guard = self.document.write();
        let _ = write_guard.apply_delta(data.clone())?;

        match self.ws_sender.send_data(data) {
            Ok(_) => {},
            Err(e) => {
                // TODO: save to local and retry
                log::error!("Send delta failed: {:?}", e);
            },
        }

        // Opti: strategy to save the document
        let save = UpdateDocParams {
            doc_id: self.id.0.clone(),
            data: write_guard.to_bytes(),
        };
        // let _ = self.persistence.save(save, pool)?;

        Ok(())
    }
}

impl WsHandler for EditDocContext {
    fn receive(&self, data: WsDocumentData) {
        match data.source {
            WsSource::Delta => {},
        }
    }
}
