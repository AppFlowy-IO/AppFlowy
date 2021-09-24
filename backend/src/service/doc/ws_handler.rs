use crate::service::{doc::read_doc, util::parse_from_bytes, ws::WsBizHandler};
use actix_web::web::Data;
use bytes::Bytes;
use dashmap::{mapref::one::Ref, DashMap};
use flowy_document::{
    protobuf::{Doc, QueryDocParams, Revision, WsDataType, WsDocumentData},
    services::doc::Document,
};
use flowy_net::errors::{internal_error, ServerError};
use flowy_ot::core::Delta;
use parking_lot::{RawRwLock, RwLock};
use protobuf::Message;
use sqlx::PgPool;
use std::sync::Arc;

#[rustfmt::skip]
//
//                 Frontend              │                 Backend
//
// ┌──────────┐        ┌──────────┐      │     ┌─────────┐            ┌───────────────┐
// │  user 1  │───────▶│WsManager │───────────▶│ws_client│───────────▶│DocWsBizHandler│
// └──────────┘        └──────────┘      │     └─────────┘            └───────────────┘
//
//   WsDocumentData────▶WsMessage ────▶ Message  ─────▶WsMessage ─────▶WsDocumentData

pub struct DocWsBizHandler {
    inner: Arc<Inner>,
}

struct Inner {
    pg_pool: Data<PgPool>,
    edited_docs: DashMap<String, Arc<RwLock<EditedDoc>>>,
}

impl DocWsBizHandler {
    pub fn new(pg_pool: Data<PgPool>) -> Self {
        Self {
            inner: Arc::new(Inner {
                edited_docs: DashMap::new(),
                pg_pool,
            }),
        }
    }
}

async fn handle_document_data(inner: Arc<Inner>, data: Bytes) -> Result<(), ServerError> {
    let document_data: WsDocumentData = parse_from_bytes(&data)?;
    match document_data.ty {
        WsDataType::Command => {},
        WsDataType::Delta => {
            let revision: Revision = parse_from_bytes(&document_data.data).unwrap();
            let edited_doc = get_edit_doc(inner, &revision.doc_id).await?;
            let _ = edited_doc.write().apply_revision(revision)?;
        },
    }

    Ok(())
}

async fn get_edit_doc(
    inner: Arc<Inner>,
    doc_id: &str,
) -> Result<Arc<RwLock<EditedDoc>>, ServerError> {
    let pg_pool = inner.pg_pool.clone();

    if let Some(doc) = inner.edited_docs.get(doc_id) {
        return Ok(doc.clone());
    }

    let params = QueryDocParams {
        doc_id: doc_id.to_string(),
        ..Default::default()
    };

    let doc = read_doc(pg_pool.get_ref(), params).await?;
    let edited_doc = Arc::new(RwLock::new(EditedDoc::new(doc)?));
    inner
        .edited_docs
        .insert(doc_id.to_string(), edited_doc.clone());
    Ok(edited_doc)
}

impl WsBizHandler for DocWsBizHandler {
    fn receive_data(&self, data: Bytes) {
        let inner = self.inner.clone();
        actix_rt::spawn(async {
            let result = handle_document_data(inner, data).await;
            match result {
                Ok(_) => {},
                Err(e) => log::error!("WsBizHandler handle data error: {:?}", e),
            }
        });
    }
}

struct EditedDoc {
    doc_id: String,
    document: Document,
}

impl EditedDoc {
    fn new(doc: Doc) -> Result<Self, ServerError> {
        let delta = Delta::from_bytes(doc.data).map_err(internal_error)?;
        let document = Document::from_delta(delta);
        Ok(Self {
            doc_id: doc.id.clone(),
            document,
        })
    }

    fn apply_revision(&mut self, revision: Revision) -> Result<(), ServerError> {
        let delta = Delta::from_bytes(revision.delta).map_err(internal_error)?;
        let _ = self
            .document
            .apply_delta(delta.clone())
            .map_err(internal_error)?;

        let json = self.document.to_json();
        let md5 = format!("{:x}", md5::compute(json));
        if md5 != revision.md5 {
            log::error!("Document conflict after apply delta {}", delta)
        }

        Ok(())
    }
}
