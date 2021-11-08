mod deps_resolve;
// mod flowy_server;
pub mod module;

use crate::deps_resolve::WorkspaceDepsResolver;
use flowy_dispatch::prelude::*;
use flowy_document::prelude::FlowyDocument;
use flowy_net::config::ServerConfig;
use flowy_user::{
    entities::UserStatus,
    services::user::{UserSession, UserSessionBuilder},
};
use flowy_workspace::prelude::WorkspaceController;
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
    root: String,
    log_filter: String,
    server_config: ServerConfig,
}

impl FlowySDKConfig {
    pub fn new(root: &str, server_config: ServerConfig) -> Self {
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
    filters.push(format!("flowy_dart_notify={}", level));
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
    pub workspace: Arc<WorkspaceController>,
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
        let flowy_document = mk_document_module(user_session.clone(), &config.server_config);
        let workspace = mk_workspace(user_session.clone(), flowy_document.clone(), &config.server_config);
        let modules = mk_modules(workspace.clone(), user_session.clone());
        let dispatch = Arc::new(EventDispatch::construct(|| modules));

        let subscribe = user_session.status_subscribe();
        listen_on_user_status_changed(&dispatch, subscribe, workspace.clone());

        Self {
            config,
            user_session,
            flowy_document,
            workspace,
            dispatch,
        }
    }

    pub fn dispatch(&self) -> Arc<EventDispatch> { self.dispatch.clone() }
}

fn listen_on_user_status_changed(
    dispatch: &EventDispatch,
    mut subscribe: broadcast::Receiver<UserStatus>,
    workspace_controller: Arc<WorkspaceController>,
) {
    dispatch.spawn(async move {
        //
        loop {
            match subscribe.recv().await {
                Ok(status) => match status {
                    UserStatus::Login { .. } => {
                        workspace_controller.user_did_login();
                    },
                    UserStatus::Expired { .. } => {
                        workspace_controller.user_session_expired();
                    },
                    UserStatus::SignUp { .. } => {
                        workspace_controller.user_did_sign_up().await;
                    },
                },
                Err(_) => {},
            }
        }
    });
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

        let _ = flowy_log::Builder::new("flowy-client", &config.root)
            .env_filter(&config.log_filter)
            .build();
    }
}

fn mk_workspace(
    user_session: Arc<UserSession>,
    flowy_document: Arc<FlowyDocument>,
    server_config: &ServerConfig,
) -> Arc<WorkspaceController> {
    let workspace_deps = WorkspaceDepsResolver::new(user_session.clone());
    let (user, database) = workspace_deps.split_into();
    let workspace_controller = flowy_workspace::module::mk_workspace(user, database, flowy_document, server_config);
    workspace_controller
}
