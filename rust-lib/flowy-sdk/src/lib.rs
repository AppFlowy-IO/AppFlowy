mod deps_resolve;
// mod flowy_server;
pub mod module;

use flowy_dispatch::prelude::*;
use flowy_document::prelude::FlowyDocument;
use flowy_net::config::ServerConfig;
use flowy_user::services::user::{UserSession, UserSessionBuilder};
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
    server_config: ServerConfig,
}

impl FlowySDKConfig {
    pub fn new(root: &str, host: &str, http_schema: &str, ws_schema: &str) -> Self {
        let server_config = ServerConfig::new(host, http_schema, ws_schema);
        FlowySDKConfig {
            root: root.to_owned(),
            log_filter: crate_log_filter(None),
            server_config,
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
    filters.push(format!("flowy_document={}", level));
    filters.push(format!("flowy_observable={}", level));
    filters.push(format!("flowy_ot={}", level));
    filters.push(format!("flowy_ws={}", level));
    filters.push(format!("info"));
    filters.join(",")
}

#[derive(Clone)]
pub struct FlowySDK {
    config: FlowySDKConfig,
    pub user_session: Arc<UserSession>,
    pub flowy_document: Arc<FlowyDocument>,
    pub dispatch: Arc<EventDispatch>,
}

impl FlowySDK {
    pub fn new(config: FlowySDKConfig) -> Self {
        init_log(&config);
        init_kv(&config.root);

        tracing::debug!("🔥 {:?}", config);
        let user_session = Arc::new(
            UserSessionBuilder::new()
                .root_dir(&config.root, &config.server_config)
                .build(),
        );
        let flowy_document = build_document_module(user_session.clone());
        let modules = build_modules(&config.server_config, user_session.clone(), flowy_document.clone());
        let dispatch = Arc::new(EventDispatch::construct(|| modules));

        Self {
            config,
            user_session,
            flowy_document,
            dispatch,
        }
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
