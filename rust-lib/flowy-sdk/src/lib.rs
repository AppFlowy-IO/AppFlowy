mod deps_resolve;
// mod flowy_server;
pub mod module;

use flowy_dispatch::prelude::*;
use module::build_modules;
pub use module::*;
use std::sync::atomic::{AtomicBool, Ordering};

static INIT_LOG: AtomicBool = AtomicBool::new(false);
pub struct FlowySDK {
    root: String,
}

impl FlowySDK {
    pub fn new(root: &str) -> Self {
        Self {
            root: root.to_owned(),
        }
    }

    pub fn construct(self) { FlowySDK::construct_with(&self.root) }

    pub fn construct_with(root: &str) {
        FlowySDK::init_log(root);

        tracing::info!("🔥 Root path: {}", root);
        match flowy_infra::kv::KVStore::init(root) {
            Ok(_) => {},
            Err(e) => tracing::error!("Init kv store failedL: {}", e),
        }
        FlowySDK::init_modules(root);
    }

    fn init_log(directory: &str) {
        if !INIT_LOG.load(Ordering::SeqCst) {
            INIT_LOG.store(true, Ordering::SeqCst);

            let _ = flowy_log::Builder::new("flowy")
                .local(directory)
                .env_filter("info")
                .build();
        }
    }

    fn init_modules(root: &str) {
        let config = ModuleConfig {
            root: root.to_owned(),
        };
        EventDispatch::construct(|| build_modules(config));
    }
}
