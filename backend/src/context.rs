use crate::service::{
    doc::manager::DocBiz,
    ws::{WsBizHandlers, WsServer},
};
use actix::Addr;
use actix_web::web::Data;
use lib_ws::WsModule;
use sqlx::PgPool;
use std::sync::Arc;

#[derive(Clone)]
pub struct AppContext {
    pub ws_server: Data<Addr<WsServer>>,
    pub pg_pool: Data<PgPool>,
    pub ws_bizs: Data<WsBizHandlers>,
    pub doc_biz: Data<Arc<DocBiz>>,
}

impl AppContext {
    pub fn new(ws_server: Addr<WsServer>, db_pool: PgPool) -> Self {
        let ws_server = Data::new(ws_server);
        let pg_pool = Data::new(db_pool);

        let mut ws_bizs = WsBizHandlers::new();
        let doc_biz = Arc::new(DocBiz::new(pg_pool.clone()));
        ws_bizs.register(WsModule::Doc, doc_biz.clone());

        AppContext {
            ws_server,
            pg_pool,
            ws_bizs: Data::new(ws_bizs),
            doc_biz: Data::new(doc_biz),
        }
    }
}
