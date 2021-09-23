use crate::service::{doc::ws_handler::DocWsBizHandler, ws::WsBizHandlers};
use flowy_ws::WsSource;
use std::sync::Arc;
use tokio::sync::RwLock;

pub mod app;
pub mod doc;
pub(crate) mod log;
pub mod user;
pub(crate) mod util;
pub mod view;
pub mod workspace;
pub mod ws;

pub fn make_ws_biz_handlers() -> WsBizHandlers {
    let mut ws_biz_handlers = WsBizHandlers::new();

    // doc
    let doc_biz_handler = DocWsBizHandler::new();
    ws_biz_handlers.register(WsSource::Doc, wrap(doc_biz_handler));

    //
    ws_biz_handlers
}

fn wrap<T>(val: T) -> Arc<RwLock<T>> { Arc::new(RwLock::new(val)) }
