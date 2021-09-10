use crate::service::ws_service::WSServer;
use actix::Addr;

use sqlx::PgPool;

pub struct AppContext {
    pub ws_server: Addr<WSServer>,
    pub pg_pool: PgPool,
}

impl AppContext {
    pub fn new(ws_server: Addr<WSServer>, db_pool: PgPool) -> Self {
        AppContext {
            ws_server,
            pg_pool: db_pool,
        }
    }
}
