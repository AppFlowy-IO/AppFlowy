use crate::{
    entities::{
        doc::{Doc, Revision},
        ws::{WsDataType, WsDocumentData},
    },
    errors::*,
    services::{
        doc::{rev_manager::RevisionManager, Document},
        util::{bytes_to_rev_id, md5},
        ws::WsDocumentHandler,
    },
};
use bytes::Bytes;

use crate::{
    entities::doc::RevType,
    services::ws::WsDocumentSender,
    sql_tables::{doc::DocTableSql, DocTableChangeset},
};
use flowy_database::ConnectionPool;
use flowy_ot::core::Delta;
use parking_lot::RwLock;
use std::{convert::TryFrom, sync::Arc};

pub type DocId = String;

pub(crate) struct EditDocContext {
    pub(crate) doc_id: DocId,
    document: Arc<RwLock<Document>>,
    rev_manager: Arc<RevisionManager>,
    pool: Arc<ConnectionPool>,
}

impl EditDocContext {
    pub(crate) async fn new(
        doc_id: &str,
        delta: Delta,
        pool: Arc<ConnectionPool>,
        ws_sender: Arc<dyn WsDocumentSender>,
    ) -> Result<Self, DocError> {
        let doc_id = doc_id.to_owned();
        let rev_manager = Arc::new(RevisionManager::new(&doc_id, 1, pool.clone(), ws_sender));
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        let edit_context = Self {
            doc_id,
            document,
            rev_manager,
            pool,
        };
        Ok(edit_context)
    }

    pub(crate) fn doc(&self) -> Doc {
        Doc {
            id: self.doc_id.clone(),
            data: self.document.read().to_json(),
            rev_id: self.rev_manager.rev_id(),
        }
    }

    #[tracing::instrument(level = "debug", skip(self, data), err)]
    pub(crate) fn compose_local_delta(&self, data: Bytes) -> Result<(), DocError> {
        let (base_rev_id, rev_id) = self.rev_manager.next_rev_id();
        let revision = Revision::new(
            base_rev_id,
            rev_id,
            data.to_vec(),
            md5(&data),
            self.doc_id.clone(),
            RevType::Local,
        );

        let _ = self.update_document(&revision)?;
        self.rev_manager.add_revision(revision);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self, revision), err)]
    pub fn update_document(&self, revision: &Revision) -> Result<(), DocError> {
        let delta = Delta::from_bytes(&revision.delta)?;
        self.document.write().compose_delta(&delta)?;
        let data = self.document.read().to_json();
        let changeset = DocTableChangeset {
            id: self.doc_id.clone(),
            data,
            revision: revision.rev_id,
        };

        let sql = DocTableSql {};
        let conn = self.pool.get().map_err(internal_error)?;
        sql.update_doc_table(changeset, &*conn);
        Ok(())
    }

    #[tracing::instrument(level = "debug", skip(self), err)]
    fn compose_remote_delta(&self) -> Result<(), DocError> {
        self.rev_manager.next_compose_revision(|revision| {
            let _ = self.update_document(revision)?;
            log::debug!("😁Document: {:?}", self.document.read().to_plain_string());
            Ok(())
        });
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
            match doc_data.ty {
                WsDataType::Rev => {
                    let bytes = Bytes::from(doc_data.data);
                    let revision = Revision::try_from(bytes)?;
                    self.rev_manager.add_revision(revision);
                    let _ = self.compose_remote_delta()?;
                },
                WsDataType::Acked => {
                    let rev_id = bytes_to_rev_id(doc_data.data)?;
                    self.rev_manager.remove(rev_id);
                },
                _ => {},
            }
            Result::<(), DocError>::Ok(())
        };

        if let Err(e) = f(doc_data) {
            log::error!("{:?}", e);
        }
    }
}
