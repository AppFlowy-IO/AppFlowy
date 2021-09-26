use crate::{
    entities::{
        doc::{Doc, Revision},
        ws::{WsDataType, WsDocumentData},
    },
    errors::*,
    services::{
        doc::{rev_manager::RevisionManager, Document},
        util::bytes_to_rev_id,
        ws::WsDocumentHandler,
    },
    sql_tables::{OpTableSql, RevTable},
};
use bytes::Bytes;

use flowy_ot::core::Delta;
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};

pub type DocId = String;

pub(crate) struct EditDocContext {
    pub(crate) id: DocId,
    document: Arc<RwLock<Document>>,
    rev_manager: Arc<RevisionManager>,
}

impl EditDocContext {
    pub(crate) fn new(doc_id: &str, delta: Delta, rev_manager: RevisionManager) -> Result<Self, DocError> {
        let id = doc_id.to_owned();
        let rev_manager = Arc::new(rev_manager);
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        let edit_context = Self {
            id,
            document,
            rev_manager,
        };
        Ok(edit_context)
    }

    pub(crate) fn doc(&self) -> Doc {
        Doc {
            id: self.id.clone(),
            data: self.document.read().to_json(),
            rev_id: self.rev_manager.rev_id(),
        }
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) fn compose_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let delta = Delta::from_bytes(&data)?;
        self.document.write().compose_delta(&delta)?;
        self.rev_manager.add_delta(data);

        Ok(())
    }
}

impl WsDocumentHandler for EditDocContext {
    fn receive(&self, doc_data: WsDocumentData) {
        let f = |doc_data: WsDocumentData| {
            match doc_data.ty {
                WsDataType::Rev => {
                    let bytes = Bytes::from(doc_data.data);
                    let revision = Revision::try_from(bytes)?;
                    self.rev_manager.add_revision(revision);
                    self.rev_manager.next_compose_delta(|delta| {
                        let _ = self.document.write().compose_delta(delta)?;
                        log::debug!("😁Document: {:?}", self.document.read().to_plain_string());
                        Ok(())
                    });
                },
                WsDataType::Acked => {
                    let rev_id = bytes_to_rev_id(doc_data.data)?;
                    self.rev_manager.remove(rev_id);
                },
            }
            Result::<(), DocError>::Ok(())
        };

        if let Err(e) = f(doc_data) {
            log::error!("{:?}", e);
        }
    }
}
