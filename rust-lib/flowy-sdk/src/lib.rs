pub mod module;
pub use module::*;

use flowy_dispatch::prelude::*;
use module::build_modules;
use std::sync::atomic::{AtomicBool, Ordering};

static INIT_LOG: AtomicBool = AtomicBool::new(false);
pub struct FlowySDK {}

impl FlowySDK {
    pub fn init_log(directory: &str) {
        if !INIT_LOG.load(Ordering::SeqCst) {
            INIT_LOG.store(true, Ordering::SeqCst);
            flowy_log::init_log("flowy", directory, "Debug").unwrap();
        }
    }

    pub fn init(path: &str) {
        tracing::info!("🔥 Root path: {}", path);
        flowy_infra::kv::KVStore::init(path);
        let config = ModuleConfig {
            root: path.to_string(),
        };
        EventDispatch::construct(|| build_modules(config));
    }
}
