use crate::{
    services::doc::manager::DocumentCore,
    web_socket::{WsBizHandlers, WsServer},
};
use actix::Addr;
use actix_web::web::Data;
use lib_ws::WSModule;
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppContext {
    pub ws_server: Data<Addr<WsServer>>,
    pub pg_pool: Data<PgPool>,
    pub ws_bizs: Data<WsBizHandlers>,
    pub document_core: Data<Arc<DocumentCore>>,
}

impl AppContext {
    pub fn new(ws_server: Addr<WsServer>, db_pool: PgPool) -> Self {
        let ws_server = Data::new(ws_server);
        let pg_pool = Data::new(db_pool);

        let mut ws_bizs = WsBizHandlers::new();
        let document_core = Arc::new(DocumentCore::new(pg_pool.clone()));
        ws_bizs.register(WSModule::Doc, document_core.clone());

        AppContext {
            ws_server,
            pg_pool,
            ws_bizs: Data::new(ws_bizs),
            document_core: Data::new(document_core),
        }
    }
}
