mod deps_resolve;
// mod flowy_server;
pub mod module;
use crate::deps_resolve::WorkspaceDepsResolver;
use backend_service::configuration::ClientServerConfiguration;
use flowy_core::{errors::WorkspaceError, module::init_core, prelude::FlowyCore};
use flowy_document::module::FlowyDocument;
use flowy_user::{
    prelude::UserStatus,
    services::user::{UserSession, UserSessionConfig},
};
use lib_dispatch::prelude::*;
use lib_infra::entities::network_state::NetworkType;
use module::mk_modules;
pub use module::*;
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};
use tokio::sync::broadcast;

static INIT_LOG: AtomicBool = AtomicBool::new(false);

#[derive(Debug, Clone)]
pub struct FlowySDKConfig {
    name: String,
    root: String,
    log_filter: String,
    server_config: ClientServerConfiguration,
}

impl FlowySDKConfig {
    pub fn new(root: &str, server_config: ClientServerConfiguration, name: &str) -> Self {
        FlowySDKConfig {
            name: name.to_owned(),
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
    let level = level.unwrap_or_else(|| std::env::var("RUST_LOG").unwrap_or_else(|_| "info".to_owned()));
    let mut filters = vec![];
    filters.push(format!("flowy_sdk={}", level));
    filters.push(format!("flowy_workspace={}", level));
    filters.push(format!("flowy_user={}", level));
    filters.push(format!("flowy_document={}", level));
    filters.push(format!("flowy_document_infra={}", level));
    filters.push(format!("dart_notify={}", level));
    filters.push(format!("lib_ot={}", level));
    filters.push(format!("lib_ws={}", level));
    filters.push(format!("lib_infra={}", level));
    filters.join(",")
}

#[derive(Clone)]
pub struct FlowySDK {
    #[allow(dead_code)]
    config: FlowySDKConfig,
    pub user_session: Arc<UserSession>,
    pub flowy_document: Arc<FlowyDocument>,
    pub core: Arc<FlowyCore>,
    pub dispatcher: Arc<EventDispatcher>,
}

impl FlowySDK {
    pub fn new(config: FlowySDKConfig) -> Self {
        init_log(&config);
        init_kv(&config.root);
        tracing::debug!("🔥 {:?}", config);

        let session_cache_key = format!("{}_session_cache", &config.name);

        let user_config = UserSessionConfig::new(&config.root, &config.server_config, &session_cache_key);
        let user_session = Arc::new(UserSession::new(user_config));
        let flowy_document = mk_document_module(user_session.clone(), &config.server_config);
        let core = mk_core(user_session.clone(), flowy_document.clone(), &config.server_config);

        let modules = mk_modules(core.clone(), user_session.clone());
        let dispatcher = Arc::new(EventDispatcher::construct(|| modules));
        _init(&dispatcher, user_session.clone(), core.clone());

        Self {
            config,
            user_session,
            flowy_document,
            core,
            dispatcher,
        }
    }

    pub fn dispatcher(&self) -> Arc<EventDispatcher> { self.dispatcher.clone() }
}

fn _init(dispatch: &EventDispatcher, user_session: Arc<UserSession>, core: Arc<FlowyCore>) {
    let user_status_subscribe = user_session.notifier.user_status_subscribe();
    let network_status_subscribe = user_session.notifier.network_type_subscribe();
    let cloned_core = core.clone();

    dispatch.spawn(async move {
        user_session.init();
        _listen_user_status(user_status_subscribe, core.clone()).await;
    });
    dispatch.spawn(async move {
        _listen_network_status(network_status_subscribe, cloned_core).await;
    });
}

async fn _listen_user_status(mut subscribe: broadcast::Receiver<UserStatus>, core: Arc<FlowyCore>) {
    while let Ok(status) = subscribe.recv().await {
        let result = || async {
            match status {
                UserStatus::Login { token } => {
                    let _ = core.user_did_sign_in(&token).await?;
                },
                UserStatus::Logout { .. } => {
                    core.user_did_logout().await;
                },
                UserStatus::Expired { .. } => {
                    core.user_session_expired().await;
                },
                UserStatus::SignUp { profile, ret } => {
                    let _ = core.user_did_sign_up(&profile.token).await?;
                    let _ = ret.send(());
                },
            }
            Ok::<(), WorkspaceError>(())
        };

        match result().await {
            Ok(_) => {},
            Err(e) => log::error!("{}", e),
        }
    }
}

async fn _listen_network_status(mut subscribe: broadcast::Receiver<NetworkType>, core: Arc<FlowyCore>) {
    while let Ok(new_type) = subscribe.recv().await {
        core.network_state_changed(new_type);
    }
}

fn init_kv(root: &str) {
    match lib_infra::kv::KV::init(root) {
        Ok(_) => {},
        Err(e) => tracing::error!("Init kv store failedL: {}", e),
    }
}

fn init_log(config: &FlowySDKConfig) {
    if !INIT_LOG.load(Ordering::SeqCst) {
        INIT_LOG.store(true, Ordering::SeqCst);

        let _ = lib_log::Builder::new("flowy-client", &config.root)
            .env_filter(&config.log_filter)
            .build();
    }
}

fn mk_core(
    user_session: Arc<UserSession>,
    flowy_document: Arc<FlowyDocument>,
    server_config: &ClientServerConfiguration,
) -> Arc<FlowyCore> {
    let workspace_deps = WorkspaceDepsResolver::new(user_session);
    let (user, database) = workspace_deps.split_into();
    init_core(user, database, flowy_document, server_config)
}
