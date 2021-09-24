use crate::service::ws::WsServer;
use actix::Addr;

use sqlx::PgPool;

pub struct AppContext {
    pub ws_server: Addr<WsServer>,
    pub pg_pool: PgPool,
}

impl AppContext {
    pub fn new(ws_server: Addr<WsServer>, db_pool: PgPool) -> Self {
        AppContext {
            ws_server,
            pg_pool: db_pool,
        }
    }
}
