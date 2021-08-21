use crate::{user_service::Auth, ws_service::WSServer};
use actix::Addr;

use sqlx::PgPool;
use std::sync::Arc;

pub struct AppContext {
    pub ws_server: Addr<WSServer>,
    pub db_pool: Arc<PgPool>,
    pub auth: Arc<Auth>,
}

impl AppContext {
    pub fn new(ws_server: Addr<WSServer>, db_pool: Arc<PgPool>, auth: Arc<Auth>) -> Self {
        AppContext {
            ws_server,
            db_pool,
            auth,
        }
    }
}
