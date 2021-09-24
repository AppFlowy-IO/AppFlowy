use crate::service::doc::update_doc;
use actix_web::web::Data;
use flowy_document::{
    protobuf::{Doc, Revision, UpdateDocParams},
    services::doc::Document,
};
use flowy_net::errors::{internal_error, ServerError};
use flowy_ot::core::Delta;
use parking_lot::RwLock;
use sqlx::PgPool;
use std::{sync::Arc, time::Duration};

pub(crate) struct EditDoc {
    doc_id: String,
    document: Arc<RwLock<Document>>,
    pg_pool: Data<PgPool>,
}

impl EditDoc {
    pub(crate) fn new(doc: Doc, pg_pool: Data<PgPool>) -> Result<Self, ServerError> {
        let delta = Delta::from_bytes(doc.data).map_err(internal_error)?;
        let document = Arc::new(RwLock::new(Document::from_delta(delta)));
        Ok(Self {
            doc_id: doc.id.clone(),
            document,
            pg_pool,
        })
    }

    #[tracing::instrument(level = "debug", skip(self, revision))]
    pub(crate) async fn apply_revision(&self, revision: Revision) -> Result<(), ServerError> {
        let delta = Delta::from_bytes(revision.delta).map_err(internal_error)?;
        match self.document.try_write_for(Duration::from_millis(300)) {
            None => {
                log::error!("Failed to acquire write lock of document");
            },
            Some(mut w) => {
                let _ = w.apply_delta(delta).map_err(internal_error)?;
            },
        }

        let md5 = format!("{:x}", md5::compute(self.document.read().to_json()));
        if md5 != revision.md5 {
            log::warn!("Document md5 not match")
        }

        let mut params = UpdateDocParams::new();
        params.set_doc_id(self.doc_id.clone());
        params.set_data(self.document.read().to_bytes());
        match update_doc(self.pg_pool.get_ref(), params).await {
            Ok(_) => {},
            Err(e) => {
                log::error!("Save doc data failed: {:?}", e);
            },
        }

        Ok(())
    }
}
