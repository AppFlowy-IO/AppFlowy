use crate::service::{doc::ws_handler::DocWsBizHandler, ws::WsBizHandlers};
use actix_web::web::Data;
use flowy_ws::WsModule;
use sqlx::PgPool;
use std::sync::Arc;

pub mod app;
pub mod doc;
pub(crate) mod log;
pub mod user;
pub(crate) mod util;
pub mod view;
pub mod workspace;
pub mod ws;

pub fn make_ws_biz_handlers(pg_pool: Data<PgPool>) -> WsBizHandlers {
    let mut ws_biz_handlers = WsBizHandlers::new();

    // doc
    let doc_biz_handler = DocWsBizHandler::new(pg_pool);
    ws_biz_handlers.register(WsModule::Doc, wrap(doc_biz_handler));

    //
    ws_biz_handlers
}

fn wrap<T>(val: T) -> Arc<T> { Arc::new(val) }
