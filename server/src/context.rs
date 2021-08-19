use crate::{config::Config, ws::WSServer};
use actix::Addr;
use std::sync::Arc;

pub struct AppContext {
    pub config: Arc<Config>,
    pub server: Addr<WSServer>,
}

impl AppContext {
    pub fn new(server: Addr<WSServer>) -> Self {
        AppContext {
            config: Arc::new(Config::new()),
            server,
        }
    }

    pub fn ws_server(&self) -> Addr<WSServer> { self.server.clone() }
}
