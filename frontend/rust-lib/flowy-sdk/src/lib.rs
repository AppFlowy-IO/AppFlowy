mod deps_resolve;
pub mod module;
use crate::deps_resolve::*;
use backend_service::configuration::ClientServerConfiguration;
use flowy_core::{controller::FolderManager, errors::FlowyError};
use flowy_document::context::DocumentContext;
use flowy_net::{
    entities::NetworkType,
    local_server::LocalServer,
    ws::connection::{listen_on_websocket, FlowyWebSocketConnect},
};
use flowy_user::services::{notifier::UserStatus, UserSession, UserSessionConfig};
use lib_dispatch::prelude::*;

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
    pub fn new(root: &str, server_config: ClientServerConfiguration, name: &str) -> Self {
        FlowySDKConfig {
            name: name.to_owned(),
            root: root.to_owned(),
            log_filter: crate_log_filter("info".to_owned()),
            server_config,
        }
    }

    pub fn log_filter(mut self, filter: &str) -> Self {
        self.log_filter = crate_log_filter(filter.to_owned());
        self
    }
}

fn crate_log_filter(level: String) -> String {
    let level = std::env::var("RUST_LOG").unwrap_or(level);
    let mut filters = vec![];
    filters.push(format!("flowy_sdk={}", level));
    filters.push(format!("flowy_core={}", level));
    filters.push(format!("flowy_user={}", level));
    filters.push(format!("flowy_document={}", level));
    filters.push(format!("flowy_collaboration={}", level));
    filters.push(format!("flowy_net={}", level));
    filters.push(format!("dart_ffi={}", "info"));
    filters.push(format!("dart_database={}", "info"));
    filters.push(format!("dart_notify={}", level));
    filters.push(format!("lib_ot={}", level));
    filters.push(format!("lib_ws={}", level));
    filters.push(format!("lib_infra={}", level));
    filters.push(format!("flowy_sync={}", level));
    filters.join(",")
}

#[derive(Clone)]
pub struct FlowySDK {
    #[allow(dead_code)]
    config: FlowySDKConfig,
    pub user_session: Arc<UserSession>,
    pub document_ctx: Arc<DocumentContext>,
    pub core: Arc<FolderManager>,
    pub dispatcher: Arc<EventDispatcher>,
    pub ws_conn: Arc<FlowyWebSocketConnect>,
    pub local_server: Option<Arc<LocalServer>>,
}

impl FlowySDK {
    pub fn new(config: FlowySDKConfig) -> Self {
        init_log(&config);
        init_kv(&config.root);
        tracing::debug!("🔥 {:?}", config);

        let ws_addr = config.server_config.ws_addr();
        let (local_server, ws_conn) = if cfg!(feature = "http_server") {
            let ws_conn = Arc::new(FlowyWebSocketConnect::new(ws_addr));
            (None, ws_conn)
        } else {
            let context = flowy_net::local_server::build_server(&config.server_config);
            let local_ws = Arc::new(context.local_ws);
            let ws_conn = Arc::new(FlowyWebSocketConnect::from_local(ws_addr, local_ws));
            (Some(Arc::new(context.local_server)), ws_conn)
        };

        let user_session = mk_user_session(&config, &local_server, &config.server_config);
        let flowy_document = mk_document(&local_server, &ws_conn, &user_session, &config.server_config);
        let core_ctx = mk_core_context(
            &local_server,
            &user_session,
            &flowy_document,
            &config.server_config,
            &ws_conn,
        );

        //
        let modules = mk_modules(&ws_conn, &core_ctx, &user_session);
        let dispatcher = Arc::new(EventDispatcher::construct(|| modules));
        _init(&local_server, &dispatcher, &ws_conn, &user_session, &core_ctx);

        Self {
            config,
            user_session,
            document_ctx: flowy_document,
            core: core_ctx,
            dispatcher,
            ws_conn,
            local_server,
        }
    }

    pub fn dispatcher(&self) -> Arc<EventDispatcher> { self.dispatcher.clone() }
}

fn _init(
    local_server: &Option<Arc<LocalServer>>,
    dispatch: &EventDispatcher,
    ws_conn: &Arc<FlowyWebSocketConnect>,
    user_session: &Arc<UserSession>,
    folder_manager: &Arc<FolderManager>,
) {
    let subscribe_user_status = user_session.notifier.subscribe_user_status();
    let subscribe_network_type = ws_conn.subscribe_network_ty();
    let folder_manager = folder_manager.clone();
    let cloned_folder_manager = folder_manager.clone();
    let user_session = user_session.clone();
    let ws_conn = ws_conn.clone();
    let local_server = local_server.clone();

    dispatch.spawn(async move {
        if let Some(local_server) = local_server.as_ref() {
            local_server.run();
        }

        user_session.init();
        ws_conn.init().await;
        listen_on_websocket(ws_conn.clone());
        _listen_user_status(ws_conn.clone(), subscribe_user_status, folder_manager.clone()).await;
    });

    dispatch.spawn(async move {
        _listen_network_status(subscribe_network_type, cloned_folder_manager).await;
    });
}

async fn _listen_user_status(
    ws_conn: Arc<FlowyWebSocketConnect>,
    mut subscribe: broadcast::Receiver<UserStatus>,
    folder_manager: Arc<FolderManager>,
) {
    while let Ok(status) = subscribe.recv().await {
        let result = || async {
            match status {
                UserStatus::Login { token, user_id } => {
                    tracing::trace!("User did login");
                    let _ = folder_manager.initialize(&token).await?;
                    let _ = ws_conn.start(token, user_id).await?;
                },
                UserStatus::Logout { .. } => {
                    tracing::trace!("User did logout");
                    folder_manager.clear().await;
                    let _ = ws_conn.stop().await;
                },
                UserStatus::Expired { .. } => {
                    tracing::trace!("User session has been expired");
                    folder_manager.clear().await;
                    let _ = ws_conn.stop().await;
                },
                UserStatus::SignUp { profile, ret } => {
                    tracing::trace!("User did sign up");
                    let _ = folder_manager.initialize_with_new_user(&profile.token).await?;
                    let _ = ws_conn.start(profile.token.clone(), profile.id.clone()).await?;
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

async fn _listen_network_status(mut subscribe: broadcast::Receiver<NetworkType>, _core: Arc<FolderManager>) {
    while let Ok(_new_type) = subscribe.recv().await {
        // core.network_state_changed(new_type);
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

fn mk_user_session(
    config: &FlowySDKConfig,
    local_server: &Option<Arc<LocalServer>>,
    server_config: &ClientServerConfiguration,
) -> Arc<UserSession> {
    let session_cache_key = format!("{}_session_cache", &config.name);
    let user_config = UserSessionConfig::new(&config.root, &session_cache_key);
    let cloud_service = UserDepsResolver::resolve(local_server, server_config);
    Arc::new(UserSession::new(user_config, cloud_service))
}

fn mk_core_context(
    local_server: &Option<Arc<LocalServer>>,
    user_session: &Arc<UserSession>,
    flowy_document: &Arc<DocumentContext>,
    server_config: &ClientServerConfiguration,
    ws_conn: &Arc<FlowyWebSocketConnect>,
) -> Arc<FolderManager> {
    CoreDepsResolver::resolve(
        local_server.clone(),
        user_session.clone(),
        server_config,
        flowy_document,
        ws_conn.clone(),
    )
}

pub fn mk_document(
    local_server: &Option<Arc<LocalServer>>,
    ws_conn: &Arc<FlowyWebSocketConnect>,
    user_session: &Arc<UserSession>,
    server_config: &ClientServerConfiguration,
) -> Arc<DocumentContext> {
    Arc::new(DocumentDepsResolver::resolve(
        local_server.clone(),
        ws_conn.clone(),
        user_session.clone(),
        server_config,
    ))
}
