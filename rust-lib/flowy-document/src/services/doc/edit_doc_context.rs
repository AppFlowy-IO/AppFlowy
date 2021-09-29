use crate::{
    entities::{
        doc::{Doc, RevType, Revision, RevisionRange},
        ws::{WsDataType, WsDocumentData},
    },
    errors::*,
    services::{
        doc::{rev_manager::RevisionManager, Document, UndoResult},
        util::bytes_to_rev_id,
        ws::{WsDocumentHandler, WsDocumentSender},
    },
    sql_tables::{doc::DocTableSql, DocTableChangeset},
};
use bytes::Bytes;
use flowy_database::ConnectionPool;
use flowy_ot::core::{Attribute, Delta, Interval};
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};

pub type DocId = String;

pub struct EditDocContext {
    pub doc_id: DocId,
    document: Arc<RwLock<Document>>,
    rev_manager: Arc<RevisionManager>,
    pool: Arc<ConnectionPool>,
}

impl EditDocContext {
    pub(crate) async fn new(
        doc: Doc,
        pool: Arc<ConnectionPool>,
        ws_sender: Arc<dyn WsDocumentSender>,
    ) -> Result<Self, DocError> {
        let delta = Delta::from_bytes(doc.data)?;
        let rev_manager = Arc::new(RevisionManager::new(&doc.id, doc.rev_id, pool.clone(), ws_sender));
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        let edit_context = Self {
            doc_id: doc.id,
            document,
            rev_manager,
            pool,
        };
        Ok(edit_context)
    }

    pub fn insert<T: ToString>(&self, index: usize, data: T) -> Result<(), DocError> {
        let delta_data = self.document.write().insert(index, data)?.to_bytes();
        let _ = self.mk_revision(&delta_data)?;
        Ok(())
    }

    pub fn delete(&self, interval: Interval) -> Result<(), DocError> {
        let delta_data = self.document.write().delete(interval)?.to_bytes();
        let _ = self.mk_revision(&delta_data)?;
        Ok(())
    }

    pub fn format(&self, interval: Interval, attribute: Attribute) -> Result<(), DocError> {
        let delta_data = self.document.write().format(interval, attribute)?.to_bytes();
        let _ = self.mk_revision(&delta_data)?;
        Ok(())
    }

    pub fn replace<T: ToString>(&mut self, interval: Interval, data: T) -> Result<(), DocError> {
        let delta_data = self.document.write().replace(interval, data)?.to_bytes();
        let _ = self.mk_revision(&delta_data)?;
        Ok(())
    }

    pub fn can_undo(&self) -> bool { self.document.read().can_undo() }

    pub fn can_redo(&self) -> bool { self.document.read().can_redo() }

    pub fn undo(&self) -> Result<UndoResult, DocError> { self.document.write().undo() }

    pub fn redo(&self) -> Result<UndoResult, DocError> { self.document.write().redo() }

    pub fn doc(&self) -> Doc {
        Doc {
            id: self.doc_id.clone(),
            data: self.document.read().to_json(),
            rev_id: self.rev_manager.rev_id(),
        }
    }

    fn mk_revision(&self, delta_data: &Bytes) -> Result<(), DocError> {
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        let delta_data = delta_data.to_vec();
        let revision = Revision::new(base_rev_id, rev_id, delta_data, &self.doc_id, RevType::Local);
        let _ = self.save_to_disk(revision.rev_id)?;
        let _ = self.rev_manager.add_revision(revision)?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) fn compose_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let delta = Delta::from_bytes(&data)?;
        self.document.write().compose_delta(&delta)?;

        let _ = self.mk_revision(&data)?;
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn compose_remote_delta(&self) -> Result<(), DocError> {
        self.rev_manager.next_compose_revision(|revision| {
            let delta = Delta::from_bytes(&revision.delta_data)?;
            self.document.write().compose_delta(&delta)?;
            let _ = self.save_to_disk(revision.rev_id)?;

            log::debug!("😁Document: {:?}", self.document.read().to_plain_string());
            Ok(())
        });
        Ok(())
    }

    #[cfg(feature = "flowy_test")]
    pub fn doc_json(&self) -> String { self.document.read().to_json() }

    #[tracing::instrument(level = "debug", skip(self, rev_id), err)]
    fn save_to_disk(&self, rev_id: i64) -> Result<(), DocError> {
        let data = self.document.read().to_json();
        let changeset = DocTableChangeset {
            id: self.doc_id.clone(),
            data,
            rev_id,
        };
        let sql = DocTableSql {};
        let conn = self.pool.get().map_err(internal_error)?;
        let _ = sql.update_doc_table(changeset, &*conn)?;
        Ok(())
    }

    // #[tracing::instrument(level = "debug", skip(self, params), err)]
    // fn update_doc_on_server(&self, params: UpdateDocParams) -> Result<(),
    //     DocError> {     let token = self.user.token()?;
    //     let server = self.server.clone();
    //     tokio::spawn(async move {
    //         match server.update_doc(&token, params).await {
    //             Ok(_) => {},
    //             Err(e) => {
    //                 // TODO: retry?
    //                 log::error!("Update doc failed: {}", e);
    //             },
    //         }
    //     });
    //     Ok(())
    // }
}

impl WsDocumentHandler for EditDocContext {
    fn receive(&self, doc_data: WsDocumentData) {
        let f = |doc_data: WsDocumentData| {
            let bytes = Bytes::from(doc_data.data);
            match doc_data.ty {
                WsDataType::PushRev => {
                    let revision = Revision::try_from(bytes)?;
                    let _ = self.rev_manager.add_revision(revision)?;
                    let _ = self.compose_remote_delta()?;
                },
                WsDataType::PullRev => {
                    let range = RevisionRange::try_from(bytes)?;
                    let _ = self.rev_manager.send_rev_with_range(range)?;
                },
                WsDataType::Acked => {
                    let rev_id = bytes_to_rev_id(bytes.to_vec())?;
                    let _ = self.rev_manager.ack(rev_id);
                },
                WsDataType::Conflict => {},
            }
            Result::<(), DocError>::Ok(())
        };

        if let Err(e) = f(doc_data) {
            log::error!("{:?}", e);
        }
    }
}
