use crate::{
    entities::{
        doc::{Doc, Revision},
        ws::{WsDataType, WsDocumentData},
    },
    errors::*,
    services::{
        doc::{rev_manager::RevisionManager, Document},
        util::{bytes_to_rev_id, md5},
        ws::{WsDocumentHandler, WsDocumentSender},
    },
    sql_tables::{OpTable, OpTableSql},
};
use bytes::Bytes;
use flowy_ot::core::Delta;
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};
use tokio::sync::mpsc::{unbounded_channel, UnboundedReceiver};

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
        let edit_context = Self { id, document, rev_manager };
        edit_context.composing_delta();

        Ok(edit_context)
    }

    pub(crate) fn doc(&self) -> Doc {
        Doc {
            id: self.id.clone(),
            data: self.document.read().to_bytes(),
            rev_id: self.rev_manager.rev(),
        }
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) fn apply_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let doc_id = self.id.clone();
        let (base_rev_id, rev_id) = self.rev_manager.next_rev();
        let revision = Revision::new(base_rev_id, rev_id, data.to_vec(), md5(&data), doc_id);

        let delta = Delta::from_bytes(data.to_vec())?;
        self.document.write().apply_delta(delta)?;

        self.rev_manager.add_local(revision);
        Ok(())
    }

    fn composing_delta(&self) {
        let rev_manager = self.rev_manager.clone();
        let document = self.document.clone();
        tokio::spawn(async move {
            let notified = rev_manager.notified();
            tokio::select! {
                _ = notified => {
                    if let Some(delta) = rev_manager.next_compose_delta() {
                        log::info!("😁receive delta: {:?}", delta);
                        document.write().apply_delta(delta).unwrap();
                        log::info!("😁Document: {:?}", document.read().to_plain_string());
                    }
                }
            }
        });
    }
}

impl WsDocumentHandler for EditDocContext {
    fn receive(&self, doc_data: WsDocumentData) {
        let f = |doc_data: WsDocumentData| {
            match doc_data.ty {
                WsDataType::Rev => {
                    let bytes = Bytes::from(doc_data.data);
                    let revision = Revision::try_from(bytes)?;
                    self.rev_manager.add_remote(revision);
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
