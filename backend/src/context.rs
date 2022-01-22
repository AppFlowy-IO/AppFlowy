use crate::services::{
    kv::PostgresKV,
    web_socket::{WSServer, WebSocketReceivers},
};
use actix::Addr;
use actix_web::web::Data;

use crate::services::{
    document::ws_receiver::{make_document_ws_receiver, HttpDocumentCloudPersistence},
    folder::ws_receiver::{make_folder_ws_receiver, HttpFolderCloudPersistence},
    kv::revision_kv::RevisionKVPersistence,
};
use flowy_collaboration::{server_document::ServerDocumentManager, server_folder::ServerFolderManager};
use lib_ws::WSChannel;
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppContext {
    pub ws_server: Data<Addr<WSServer>>,
    pub persistence: Data<Arc<FlowyPersistence>>,
    pub ws_receivers: Data<WebSocketReceivers>,
    pub document_manager: Data<Arc<ServerDocumentManager>>,
    pub folder_manager: Data<Arc<ServerFolderManager>>,
}

impl AppContext {
    pub fn new(ws_server: Addr<WSServer>, pg_pool: PgPool) -> Self {
        let ws_server = Data::new(ws_server);
        let mut ws_receivers = WebSocketReceivers::new();

        let document_store = make_document_kv_store(pg_pool.clone());
        let folder_store = make_folder_kv_store(pg_pool.clone());
        let flowy_persistence = Arc::new(FlowyPersistence {
            pg_pool,
            document_store,
            folder_store,
        });

        let document_persistence = Arc::new(HttpDocumentCloudPersistence(flowy_persistence.document_kv_store()));
        let document_manager = Arc::new(ServerDocumentManager::new(document_persistence));
        let document_ws_receiver = make_document_ws_receiver(flowy_persistence.clone(), document_manager.clone());
        ws_receivers.set(WSChannel::Document, document_ws_receiver);

        let folder_persistence = Arc::new(HttpFolderCloudPersistence(flowy_persistence.folder_kv_store()));
        let folder_manager = Arc::new(ServerFolderManager::new(folder_persistence));
        let folder_ws_receiver = make_folder_ws_receiver(flowy_persistence.clone(), folder_manager.clone());
        ws_receivers.set(WSChannel::Folder, folder_ws_receiver);

        AppContext {
            ws_server,
            persistence: Data::new(flowy_persistence),
            ws_receivers: Data::new(ws_receivers),
            document_manager: Data::new(document_manager),
            folder_manager: Data::new(folder_manager),
        }
    }
}

pub type DocumentRevisionKV = RevisionKVPersistence;
pub type FolderRevisionKV = RevisionKVPersistence;

fn make_document_kv_store(pg_pool: PgPool) -> Arc<DocumentRevisionKV> {
    let kv_impl = Arc::new(PostgresKV { pg_pool });
    Arc::new(DocumentRevisionKV::new(kv_impl))
}

fn make_folder_kv_store(pg_pool: PgPool) -> Arc<FolderRevisionKV> {
    let kv_impl = Arc::new(PostgresKV { pg_pool });
    Arc::new(FolderRevisionKV::new(kv_impl))
}

#[derive(Clone)]
pub struct FlowyPersistence {
    pg_pool: PgPool,
    document_store: Arc<DocumentRevisionKV>,
    folder_store: Arc<FolderRevisionKV>,
}

impl FlowyPersistence {
    pub fn pg_pool(&self) -> PgPool { self.pg_pool.clone() }

    pub fn document_kv_store(&self) -> Arc<DocumentRevisionKV> { self.document_store.clone() }

    pub fn folder_kv_store(&self) -> Arc<FolderRevisionKV> { self.folder_store.clone() }
}
