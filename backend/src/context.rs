use crate::services::{
    kv::PostgresKV,
    web_socket::{WSServer, WebSocketReceivers},
};
use actix::Addr;
use actix_web::web::Data;

use crate::services::document::{controller::make_document_ws_receiver, persistence::DocumentKVPersistence};
use lib_ws::WSModule;
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppContext {
    pub ws_server: Data<Addr<WSServer>>,
    pub persistence: Data<Arc<FlowyPersistence>>,
    pub ws_receivers: Data<WebSocketReceivers>,
}

impl AppContext {
    pub fn new(ws_server: Addr<WSServer>, pg_pool: PgPool) -> Self {
        let ws_server = Data::new(ws_server);
        let mut ws_receivers = WebSocketReceivers::new();

        let kv_store = make_document_kv_store(pg_pool.clone());
        let persistence = Arc::new(FlowyPersistence { pg_pool, kv_store });

        let document_ws_receiver = make_document_ws_receiver(persistence.clone());
        ws_receivers.set(WSModule::Doc, document_ws_receiver);
        AppContext {
            ws_server,
            persistence: Data::new(persistence),
            ws_receivers: Data::new(ws_receivers),
        }
    }
}

fn make_document_kv_store(pg_pool: PgPool) -> Arc<DocumentKVPersistence> {
    let kv_impl = Arc::new(PostgresKV { pg_pool });
    Arc::new(DocumentKVPersistence::new(kv_impl))
}

#[derive(Clone)]
pub struct FlowyPersistence {
    pg_pool: PgPool,
    kv_store: Arc<DocumentKVPersistence>,
}

impl FlowyPersistence {
    pub fn pg_pool(&self) -> PgPool { self.pg_pool.clone() }

    pub fn kv_store(&self) -> Arc<DocumentKVPersistence> { self.kv_store.clone() }
}
