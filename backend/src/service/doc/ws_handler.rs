use super::edit_doc::EditDoc;
use crate::service::{doc::read_doc, util::parse_from_bytes, ws::WsBizHandler};
use actix_web::web::Data;
use bytes::Bytes;
use flowy_document::{
    protobuf::{QueryDocParams, Revision, WsDataType, WsDocumentData},
    services::doc::Document,
};
use flowy_net::errors::ServerError;
use parking_lot::{Mutex, RwLock, RwLockUpgradableReadGuard};
use protobuf::Message;
use sqlx::PgPool;
use std::{collections::HashMap, sync::Arc};

pub struct DocWsBizHandler {
    inner: Arc<Inner>,
}

impl DocWsBizHandler {
    pub fn new(pg_pool: Data<PgPool>) -> Self {
        Self {
            inner: Arc::new(Inner::new(pg_pool)),
        }
    }
}

impl WsBizHandler for DocWsBizHandler {
    fn receive_data(&self, data: Bytes) {
        let inner = self.inner.clone();
        actix_rt::spawn(async move {
            let result = inner.handle(data).await;
            match result {
                Ok(_) => {},
                Err(e) => log::error!("WsBizHandler handle data error: {:?}", e),
            }
        });
    }
}

struct Inner {
    pg_pool: Data<PgPool>,
    edit_docs: RwLock<HashMap<String, Arc<EditDoc>>>,
}

impl Inner {
    fn new(pg_pool: Data<PgPool>) -> Self {
        Self {
            pg_pool,
            edit_docs: RwLock::new(HashMap::new()),
        }
    }

    async fn handle(&self, data: Bytes) -> Result<(), ServerError> {
        let document_data: WsDocumentData = parse_from_bytes(&data)?;

        match document_data.ty {
            WsDataType::Command => {},
            WsDataType::Delta => {
                let revision: Revision = parse_from_bytes(&document_data.data)?;
                let edited_doc = self.get_edit_doc(&revision.doc_id).await?;
                tokio::spawn(async move {
                    edited_doc.apply_revision(revision).await.unwrap();
                });
            },
        }

        Ok(())
    }

    async fn get_edit_doc(&self, doc_id: &str) -> Result<Arc<EditDoc>, ServerError> {
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
            let edit_doc = Arc::new(EditDoc::new(doc, self.pg_pool.clone())?);
            edit_docs.insert(doc_id.to_string(), edit_doc.clone());
            Ok(edit_doc)
        }
    }
}
