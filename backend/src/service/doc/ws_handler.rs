use super::edit_doc_context::EditDocContext;
use crate::service::{
    doc::read_doc,
    util::parse_from_bytes,
    ws::{WsBizHandler, WsClientData},
};
use actix_web::web::Data;

use flowy_document::protobuf::{QueryDocParams, Revision, WsDataType, WsDocumentData};
use flowy_net::errors::ServerError;
use parking_lot::{RwLock, RwLockUpgradableReadGuard};
use protobuf::Message;
use sqlx::PgPool;
use std::{collections::HashMap, sync::Arc};

pub struct DocWsBizHandler {
    doc_manager: Arc<EditDocManager>,
}

impl DocWsBizHandler {
    pub fn new(pg_pool: Data<PgPool>) -> Self {
        Self {
            doc_manager: Arc::new(EditDocManager::new(pg_pool)),
        }
    }
}

impl WsBizHandler for DocWsBizHandler {
    fn receive_data(&self, client_data: WsClientData) {
        let doc_manager = self.doc_manager.clone();
        actix_rt::spawn(async move {
            let result = doc_manager.handle(client_data).await;
            match result {
                Ok(_) => {},
                Err(e) => log::error!("WsBizHandler handle data error: {:?}", e),
            }
        });
    }
}

struct EditDocManager {
    pg_pool: Data<PgPool>,
    edit_docs: RwLock<HashMap<String, Arc<EditDocContext>>>,
}

impl EditDocManager {
    fn new(pg_pool: Data<PgPool>) -> Self {
        Self {
            pg_pool,
            edit_docs: RwLock::new(HashMap::new()),
        }
    }

    async fn handle(&self, client_data: WsClientData) -> Result<(), ServerError> {
        let document_data: WsDocumentData = parse_from_bytes(&client_data.data)?;

        match document_data.ty {
            WsDataType::Acked => {},
            WsDataType::Rev => {
                let revision: Revision = parse_from_bytes(&document_data.data)?;
                let edited_doc = self.get_edit_doc(&revision.doc_id).await?;
                tokio::spawn(async move {
                    match edited_doc
                        .apply_revision(client_data.socket, revision)
                        .await
                    {
                        Ok(_) => {},
                        Err(e) => log::error!("Doc apply revision failed: {:?}", e),
                    }
                });
            },
        }

        Ok(())
    }

    async fn get_edit_doc(&self, doc_id: &str) -> Result<Arc<EditDocContext>, ServerError> {
        // Opti: using lock free map instead?
        let edit_docs = self.edit_docs.upgradable_read();
        if let Some(doc) = edit_docs.get(doc_id) {
            return Ok(doc.clone());
        } else {
            let mut edit_docs = RwLockUpgradableReadGuard::upgrade(edit_docs);
            let pg_pool = self.pg_pool.clone();
            let params = QueryDocParams {
                doc_id: doc_id.to_string(),
                ..Default::default()
            };

            let doc = read_doc(pg_pool.get_ref(), params).await?;
            let edit_doc = Arc::new(EditDocContext::new(doc, self.pg_pool.clone())?);
            edit_docs.insert(doc_id.to_string(), edit_doc.clone());
            Ok(edit_doc)
        }
    }
}
