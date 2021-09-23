use crate::service::{util::parse_from_bytes, ws::WsBizHandler};
use actix_web::web::Data;
use bytes::Bytes;
use dashmap::DashMap;
use flowy_document::{
    protobuf::{Revision, WsDataType, WsDocumentData},
    services::doc::Document,
};
use parking_lot::RwLock;
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
    pg_pool: Data<PgPool>,
    edit_docs: DashMap<String, Arc<RwLock<EditDoc>>>,
}

impl DocWsBizHandler {
    pub fn new(pg_pool: Data<PgPool>) -> Self {
        Self {
            edit_docs: DashMap::new(),
            pg_pool,
        }
    }
}

impl WsBizHandler for DocWsBizHandler {
    fn receive_data(&self, data: Bytes) {
        let document_data: WsDocumentData = parse_from_bytes(&data).unwrap();
        match document_data.ty {
            WsDataType::Command => {},
            WsDataType::Delta => {
                let revision: Revision = parse_from_bytes(&document_data.data).unwrap();
                log::warn!("{:?}", revision);
            },
        }
    }
}

pub struct EditDoc {
    doc_id: String,
    document: Document,
}
