mod deps_resolve;
mod flowy_server;
pub mod module;

pub use crate::flowy_server::{ArcFlowyServer, FlowyServerMocker};
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
        let server = Arc::new(FlowyServerMocker {});
        Self {
            root: root.to_owned(),
            server,
        }
    }

    pub fn construct(self) { FlowySDK::construct_with(&self.root, self.server.clone()) }

    pub fn construct_with(root: &str, server: ArcFlowyServer) {
        FlowySDK::init_log(root);

        tracing::info!("🔥 Root path: {}", root);
        match flowy_infra::kv::KVStore::init(root) {
            Ok(_) => {},
            Err(e) => tracing::error!("Init kv store failedL: {}", e),
        }
        FlowySDK::init_modules(root, server);
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
