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

#[derive(Debug, Clone)]
pub struct FlowySDKConfig {
    root: String,
    log_filter: String,
}

impl FlowySDKConfig {
    pub fn new(root: &str) -> Self {
        FlowySDKConfig {
            root: root.to_owned(),
            log_filter: crate_log_filter(None),
        }
    }

    pub fn log_filter(mut self, filter: &str) -> Self {
        self.log_filter = crate_log_filter(Some(filter.to_owned()));
        self
    }
}

fn crate_log_filter(level: Option<String>) -> String {
    let level = level.unwrap_or(std::env::var("RUST_LOG").unwrap_or("info".to_owned()));
    let mut filters = vec![];
    filters.push(format!("flowy_sdk={}", level));
    filters.push(format!("flowy_workspace={}", level));
    filters.push(format!("flowy_user={}", level));
    filters.push(format!("info"));
    filters.join(",")
}

#[derive(Clone)]
pub struct FlowySDK {
    config: FlowySDKConfig,
    dispatch: Arc<EventDispatch>,
}

impl FlowySDK {
    pub fn new(config: FlowySDKConfig) -> Self {
        init_log(&config);
        init_kv(&config.root);

        tracing::debug!("🔥 {:?}", config);
        let dispatch = Arc::new(init_dispatch(&config.root));

        Self { config, dispatch }
    }

    pub fn dispatch(&self) -> Arc<EventDispatch> { self.dispatch.clone() }
}

fn init_kv(root: &str) {
    match flowy_infra::kv::KV::init(root) {
        Ok(_) => {},
        Err(e) => tracing::error!("Init kv store failedL: {}", e),
    }
}

fn init_log(config: &FlowySDKConfig) {
    if !INIT_LOG.load(Ordering::SeqCst) {
        INIT_LOG.store(true, Ordering::SeqCst);

        let _ = flowy_log::Builder::new("flowy")
            .local(&config.root)
            .env_filter(&config.log_filter)
            .build();
    }
}

fn init_dispatch(root: &str) -> EventDispatch {
    let config = ModuleConfig { root: root.to_owned() };
    let dispatch = EventDispatch::construct(|| build_modules(config));
    dispatch
}
