mod deps_resolve;
// mod flowy_server;
pub mod module;

use flowy_dispatch::prelude::*;
use module::build_modules;
pub use module::*;
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

static INIT_LOG: AtomicBool = AtomicBool::new(false);
#[derive(Clone)]
pub struct FlowySDK {
    root: String,
    dispatch: Arc<EventDispatch>,
}

impl FlowySDK {
    pub fn new(root: &str) -> Self {
        init_log(root);
        init_kv(root);

        tracing::info!("🔥 user folder: {}", root);
        let dispatch = Arc::new(init_dispatch(root));
        let root = root.to_owned();
        Self { root, dispatch }
    }

    pub fn dispatch(&self) -> Arc<EventDispatch> { self.dispatch.clone() }
}

fn init_kv(root: &str) {
    match flowy_infra::kv::KV::init(root) {
        Ok(_) => {},
        Err(e) => tracing::error!("Init kv store failedL: {}", e),
    }
}

fn init_log(directory: &str) {
    if !INIT_LOG.load(Ordering::SeqCst) {
        INIT_LOG.store(true, Ordering::SeqCst);

        let _ = flowy_log::Builder::new("flowy").local(directory).env_filter("info").build();
    }
}

fn init_dispatch(root: &str) -> EventDispatch {
    let config = ModuleConfig { root: root.to_owned() };
    let dispatch = EventDispatch::construct(|| build_modules(config));
    dispatch
}
