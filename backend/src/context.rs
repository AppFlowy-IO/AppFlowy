use crate::{config::Config, user_service::Auth, ws_service::WSServer};
use actix::Addr;

use sqlx::PgPool;
use std::sync::Arc;

pub struct AppContext {
    pub config: Arc<Config>,
    pub ws_server: Addr<WSServer>,
    pub db_pool: Arc<PgPool>,
    pub auth: Arc<Auth>,
}

impl AppContext {
    pub fn new(
        config: Arc<Config>,
        ws_server: Addr<WSServer>,
        db_pool: Arc<PgPool>,
        auth: Arc<Auth>,
    ) -> Self {
        AppContext {
            config,
            ws_server,
            db_pool,
            auth,
        }
    }
}
