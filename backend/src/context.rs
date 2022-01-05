use crate::services::{
    kv::PostgresKV,
    web_socket::{WSServer, WebSocketReceivers},
};
use actix::Addr;
use actix_web::web::Data;

<<<<<<< HEAD
<<<<<<< HEAD
use crate::services::document::{persistence::DocumentKVPersistence, ws_receiver::make_document_ws_receiver};
=======
=======
>>>>>>> upstream/main
use crate::services::document::{
    persistence::DocumentKVPersistence,
    ws_receiver::{make_document_ws_receiver, DocumentPersistenceImpl},
};
use flowy_collaboration::sync::ServerDocumentManager;
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
use lib_ws::WSModule;
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppContext {
    pub ws_server: Data<Addr<WSServer>>,
    pub persistence: Data<Arc<FlowyPersistence>>,
    pub ws_receivers: Data<WebSocketReceivers>,
<<<<<<< HEAD
<<<<<<< HEAD
=======
    pub document_manager: Data<Arc<ServerDocumentManager>>,
>>>>>>> upstream/main
=======
    pub document_manager: Data<Arc<ServerDocumentManager>>,
>>>>>>> upstream/main
}

impl AppContext {
    pub fn new(ws_server: Addr<WSServer>, pg_pool: PgPool) -> Self {
        let ws_server = Data::new(ws_server);
        let mut ws_receivers = WebSocketReceivers::new();

        let kv_store = make_document_kv_store(pg_pool.clone());
        let persistence = Arc::new(FlowyPersistence { pg_pool, kv_store });

<<<<<<< HEAD
<<<<<<< HEAD
        let document_ws_receiver = make_document_ws_receiver(persistence.clone());
=======
=======
>>>>>>> upstream/main
        let document_persistence = Arc::new(DocumentPersistenceImpl(persistence.clone()));
        let document_manager = Arc::new(ServerDocumentManager::new(document_persistence));

        let document_ws_receiver = make_document_ws_receiver(persistence.clone(), document_manager.clone());
<<<<<<< HEAD
>>>>>>> upstream/main
=======
>>>>>>> upstream/main
        ws_receivers.set(WSModule::Doc, document_ws_receiver);
        AppContext {
            ws_server,
            persistence: Data::new(persistence),
            ws_receivers: Data::new(ws_receivers),
<<<<<<< HEAD
<<<<<<< HEAD
=======
            document_manager: Data::new(document_manager),
>>>>>>> upstream/main
=======
            document_manager: Data::new(document_manager),
>>>>>>> upstream/main
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
