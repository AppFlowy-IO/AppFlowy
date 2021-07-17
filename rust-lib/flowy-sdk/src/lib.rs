mod flowy_server;
pub mod module;

use crate::flowy_server::{ArcFlowyServer, MockFlowyServer};
use flowy_dispatch::prelude::*;
use module::build_modules;
pub use module::*;
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

static INIT_LOG: AtomicBool = AtomicBool::new(false);
pub struct FlowySDK {
    root: String,
    server: ArcFlowyServer,
}

impl FlowySDK {
    pub fn new(root: &str) -> Self {
        let server = Arc::new(MockFlowyServer {});
        Self {
            root: root.to_owned(),
            server,
        }
    }

    pub fn construct(self) {
        FlowySDK::init_log(&self.root);

        tracing::info!("🔥 Root path: {}", self.root);
        let _ = flowy_infra::kv::KVStore::init(&self.root);
        FlowySDK::init_modules(&self.root, self.server);
    }

    fn init_log(directory: &str) {
        if !INIT_LOG.load(Ordering::SeqCst) {
            INIT_LOG.store(true, Ordering::SeqCst);
            flowy_log::init_log("flowy", directory, "Debug").unwrap();
        }
    }

    fn init_modules(root: &str, server: ArcFlowyServer) {
        let config = ModuleConfig {
            root: root.to_owned(),
        };
        EventDispatch::construct(|| build_modules(config, server));
    }
}
