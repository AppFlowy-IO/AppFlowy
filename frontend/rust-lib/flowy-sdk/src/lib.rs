mod deps_resolve;
pub mod module;
use crate::deps_resolve::{DocumentDepsResolver, WorkspaceDepsResolver};
use backend_service::configuration::ClientServerConfiguration;
use flowy_core::{context::CoreContext, errors::FlowyError, module::init_core};
use flowy_document::context::DocumentContext;
use flowy_net::{
    entities::NetworkType,
    services::{
        local_ws::LocalWebSocket,
        ws_conn::{listen_on_websocket, FlowyRawWebSocket, FlowyWebSocketConnect},
    },
};
use flowy_user::{
    prelude::UserStatus,
    services::user::{UserSession, UserSessionConfig},
};
use lib_dispatch::prelude::*;
use lib_ws::WSController;
use module::mk_modules;
pub use module::*;
use std::{
    fmt,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};
use tokio::sync::broadcast;

static INIT_LOG: AtomicBool = AtomicBool::new(false);

#[derive(Clone)]
pub struct FlowySDKConfig {
    name: String,
    root: String,
    log_filter: String,
    server_config: ClientServerConfiguration,
    ws: Arc<dyn FlowyRawWebSocket>,
}

impl fmt::Debug for FlowySDKConfig {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("FlowySDKConfig")
            .field("name", &self.name)
            .field("root", &self.root)
            .field("server_config", &self.server_config)
            .finish()
    }
}

impl FlowySDKConfig {
    pub fn new(
        root: &str,
        server_config: ClientServerConfiguration,
        name: &str,
        ws: Option<Arc<dyn FlowyRawWebSocket>>,
    ) -> Self {
        let ws = ws.unwrap_or_else(default_web_socket);
        FlowySDKConfig {
            name: name.to_owned(),
            root: root.to_owned(),
            log_filter: crate_log_filter(None),
            server_config,
            ws,
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
    filters.push(format!("flowy_core={}", level));
    filters.push(format!("flowy_user={}", level));
    filters.push(format!("flowy_document={}", level));
    filters.push(format!("flowy_collaboration={}", level));
    filters.push(format!("flowy_net={}", level));
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
    pub document_ctx: Arc<DocumentContext>,
    pub core: Arc<CoreContext>,
    pub dispatcher: Arc<EventDispatcher>,
    pub ws_conn: Arc<FlowyWebSocketConnect>,
}

impl FlowySDK {
    pub fn new(config: FlowySDKConfig) -> Self {
        init_log(&config);
        init_kv(&config.root);
        tracing::debug!("🔥 {:?}", config);

        let ws_conn = Arc::new(FlowyWebSocketConnect::new(
            config.server_config.ws_addr(),
            config.ws.clone(),
        ));
        let user_session = mk_user_session(&config);
        let flowy_document = mk_document(&ws_conn, &user_session, &config.server_config);
        let core_ctx = mk_core_context(&user_session, &flowy_document, &config.server_config);

        //
        let modules = mk_modules(&ws_conn, &core_ctx, &user_session);
        let dispatcher = Arc::new(EventDispatcher::construct(|| modules));
        _init(&dispatcher, &ws_conn, &user_session, &core_ctx);

        Self {
            config,
            user_session,
            document_ctx: flowy_document,
            core: core_ctx,
            dispatcher,
            ws_conn,
        }
    }

    pub fn dispatcher(&self) -> Arc<EventDispatcher> { self.dispatcher.clone() }
}

fn _init(
    dispatch: &EventDispatcher,
    ws_conn: &Arc<FlowyWebSocketConnect>,
    user_session: &Arc<UserSession>,
    core: &Arc<CoreContext>,
) {
    let subscribe_user_status = user_session.notifier.subscribe_user_status();
    let subscribe_network_type = ws_conn.subscribe_network_ty();
    let core = core.clone();
    let cloned_core = core.clone();
    let user_session = user_session.clone();
    let ws_conn = ws_conn.clone();

    dispatch.spawn(async move {
        user_session.init();
        listen_on_websocket(ws_conn.clone());
        _listen_user_status(ws_conn.clone(), subscribe_user_status, core.clone()).await;
    });

    dispatch.spawn(async move {
        _listen_network_status(subscribe_network_type, cloned_core).await;
    });
}

async fn _listen_user_status(
    ws_conn: Arc<FlowyWebSocketConnect>,
    mut subscribe: broadcast::Receiver<UserStatus>,
    core: Arc<CoreContext>,
) {
    while let Ok(status) = subscribe.recv().await {
        let result = || async {
            match status {
                UserStatus::Login { token } => {
                    let _ = core.user_did_sign_in(&token).await?;
                    let _ = ws_conn.start(token).await?;
                },
                UserStatus::Logout { .. } => {
                    core.user_did_logout().await;
                    let _ = ws_conn.stop().await;
                },
                UserStatus::Expired { .. } => {
                    core.user_session_expired().await;
                    let _ = ws_conn.stop().await;
                },
                UserStatus::SignUp { profile, ret } => {
                    let _ = core.user_did_sign_up(&profile.token).await?;
                    let _ = ws_conn.start(profile.token.clone()).await?;
                    let _ = ret.send(());
                },
            }
            Ok::<(), FlowyError>(())
        };

        match result().await {
            Ok(_) => {},
            Err(e) => log::error!("{}", e),
        }
    }
}

async fn _listen_network_status(mut subscribe: broadcast::Receiver<NetworkType>, core: Arc<CoreContext>) {
    while let Ok(new_type) = subscribe.recv().await {
        core.network_state_changed(new_type);
    }
}

fn init_kv(root: &str) {
    match flowy_database::kv::KV::init(root) {
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

fn mk_user_session(config: &FlowySDKConfig) -> Arc<UserSession> {
    let session_cache_key = format!("{}_session_cache", &config.name);
    let user_config = UserSessionConfig::new(&config.root, &config.server_config, &session_cache_key);
    Arc::new(UserSession::new(user_config))
}

fn mk_core_context(
    user_session: &Arc<UserSession>,
    flowy_document: &Arc<DocumentContext>,
    server_config: &ClientServerConfiguration,
) -> Arc<CoreContext> {
    let workspace_deps = WorkspaceDepsResolver::new(user_session.clone());
    let (user, database) = workspace_deps.split_into();
    init_core(user, database, flowy_document.clone(), server_config)
}

fn default_web_socket() -> Arc<dyn FlowyRawWebSocket> {
    if cfg!(feature = "http_server") {
        Arc::new(Arc::new(WSController::new()))
    } else {
        Arc::new(LocalWebSocket::default())
    }
}

pub fn mk_document(
    ws_manager: &Arc<FlowyWebSocketConnect>,
    user_session: &Arc<UserSession>,
    server_config: &ClientServerConfiguration,
) -> Arc<DocumentContext> {
    let (user, ws_receivers, ws_sender) = DocumentDepsResolver::resolve(ws_manager.clone(), user_session.clone());
    Arc::new(DocumentContext::new(user, ws_receivers, ws_sender, server_config))
}
