mod deps_resolve;
pub mod module;
pub use flowy_net::get_client_server_configuration;

use crate::deps_resolve::*;

use flowy_document::entities::DocumentVersionPB;
use flowy_document::{DocumentConfig, DocumentManager};
use flowy_folder::entities::ViewDataFormatPB;
use flowy_folder::{errors::FlowyError, manager::FolderManager};
use flowy_grid::manager::GridManager;
use flowy_net::ClientServerConfiguration;
use flowy_net::{
    entities::NetworkType,
    local_server::LocalServer,
    ws::connection::{listen_on_websocket, FlowyWebSocketConnect},
};
use flowy_task::{TaskDispatcher, TaskRunner};
use flowy_user::services::{notifier::UserStatus, UserSession, UserSessionConfig};
use lib_dispatch::prelude::*;
use lib_dispatch::runtime::tokio_default_runtime;
use module::make_plugins;
pub use module::*;
use std::time::Duration;
use std::{
    fmt,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};
use tokio::sync::{broadcast, RwLock};

static INIT_LOG: AtomicBool = AtomicBool::new(false);

#[derive(Clone)]
pub struct FlowySDKConfig {
    /// Different `FlowySDK` instance should have different name
    name: String,
    /// Panics if the `root` path is not existing
    root: String,
    log_filter: String,
    server_config: ClientServerConfiguration,
    pub document: DocumentConfig,
}

impl fmt::Debug for FlowySDKConfig {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("FlowySDKConfig")
            .field("root", &self.root)
            .field("server-config", &self.server_config)
            .field("document-config", &self.document)
            .finish()
    }
}

impl FlowySDKConfig {
    pub fn new(root: &str, name: String, server_config: ClientServerConfiguration) -> Self {
        FlowySDKConfig {
            name,
            root: root.to_owned(),
            log_filter: crate_log_filter("info".to_owned()),
            server_config,
            document: DocumentConfig::default(),
        }
    }

    pub fn with_document_version(mut self, version: DocumentVersionPB) -> Self {
        self.document.version = version;
        self
    }

    pub fn log_filter(mut self, level: &str) -> Self {
        self.log_filter = crate_log_filter(level.to_owned());
        self
    }
}

fn crate_log_filter(level: String) -> String {
    let level = std::env::var("RUST_LOG").unwrap_or(level);
    let mut filters = vec![];
    filters.push(format!("flowy_sdk={}", level));
    filters.push(format!("flowy_folder={}", level));
    filters.push(format!("flowy_user={}", level));
    filters.push(format!("flowy_document={}", level));
    filters.push(format!("flowy_grid={}", level));
    filters.push(format!("flowy_collaboration={}", "info"));
    filters.push(format!("dart_notify={}", level));
    filters.push(format!("lib_ot={}", level));
    filters.push(format!("lib_ws={}", level));
    filters.push(format!("lib_infra={}", level));
    filters.push(format!("flowy_sync={}", level));
    filters.push(format!("flowy_revision={}", level));
    filters.push(format!("flowy_task={}", level));
    // filters.push(format!("lib_dispatch={}", level));

    filters.push(format!("dart_ffi={}", "info"));
    filters.push(format!("flowy_database={}", level));
    filters.push(format!("flowy_net={}", "info"));
    filters.join(",")
}

#[derive(Clone)]
pub struct FlowySDK {
    #[allow(dead_code)]
    pub config: FlowySDKConfig,
    pub user_session: Arc<UserSession>,
    pub document_manager: Arc<DocumentManager>,
    pub folder_manager: Arc<FolderManager>,
    pub grid_manager: Arc<GridManager>,
    pub event_dispatcher: Arc<AFPluginDispatcher>,
    pub ws_conn: Arc<FlowyWebSocketConnect>,
    pub local_server: Option<Arc<LocalServer>>,
    pub task_dispatcher: Arc<RwLock<TaskDispatcher>>,
}

impl FlowySDK {
    pub fn new(config: FlowySDKConfig) -> Self {
        init_log(&config);
        init_kv(&config.root);
        tracing::debug!("🔥 {:?}", config);
        let runtime = tokio_default_runtime().unwrap();
        let task_scheduler = TaskDispatcher::new(Duration::from_secs(2));
        let task_dispatcher = Arc::new(RwLock::new(task_scheduler));
        runtime.spawn(TaskRunner::run(task_dispatcher.clone()));

        let (local_server, ws_conn) = mk_local_server(&config.server_config);
        let (user_session, document_manager, folder_manager, local_server, grid_manager) = runtime.block_on(async {
            let user_session = mk_user_session(&config, &local_server, &config.server_config);
            let document_manager = DocumentDepsResolver::resolve(
                local_server.clone(),
                ws_conn.clone(),
                user_session.clone(),
                &config.server_config,
                &config.document,
            );

            let grid_manager =
                GridDepsResolver::resolve(ws_conn.clone(), user_session.clone(), task_dispatcher.clone()).await;

            let folder_manager = FolderDepsResolver::resolve(
                local_server.clone(),
                user_session.clone(),
                &config.server_config,
                &ws_conn,
                &document_manager,
                &grid_manager,
            )
            .await;

            if let Some(local_server) = local_server.as_ref() {
                local_server.run();
            }
            ws_conn.init().await;
            (
                user_session,
                document_manager,
                folder_manager,
                local_server,
                grid_manager,
            )
        });

        let event_dispatcher = Arc::new(AFPluginDispatcher::construct(runtime, || {
            make_plugins(
                &ws_conn,
                &folder_manager,
                &grid_manager,
                &user_session,
                &document_manager,
            )
        }));

        _start_listening(
            &config,
            &event_dispatcher,
            &ws_conn,
            &user_session,
            &document_manager,
            &folder_manager,
            &grid_manager,
        );

        Self {
            config,
            user_session,
            document_manager,
            folder_manager,
            grid_manager,
            event_dispatcher,
            ws_conn,
            local_server,
            task_dispatcher,
        }
    }

    pub fn dispatcher(&self) -> Arc<AFPluginDispatcher> {
        self.event_dispatcher.clone()
    }
}

fn _start_listening(
    config: &FlowySDKConfig,
    event_dispatcher: &AFPluginDispatcher,
    ws_conn: &Arc<FlowyWebSocketConnect>,
    user_session: &Arc<UserSession>,
    document_manager: &Arc<DocumentManager>,
    folder_manager: &Arc<FolderManager>,
    grid_manager: &Arc<GridManager>,
) {
    let subscribe_user_status = user_session.notifier.subscribe_user_status();
    let subscribe_network_type = ws_conn.subscribe_network_ty();
    let folder_manager = folder_manager.clone();
    let grid_manager = grid_manager.clone();
    let cloned_folder_manager = folder_manager.clone();
    let ws_conn = ws_conn.clone();
    let user_session = user_session.clone();
    let document_manager = document_manager.clone();
    let config = config.clone();

    event_dispatcher.spawn(async move {
        user_session.init();
        listen_on_websocket(ws_conn.clone());
        _listen_user_status(
            config,
            ws_conn.clone(),
            subscribe_user_status,
            document_manager,
            folder_manager,
            grid_manager,
        )
        .await;
    });

    event_dispatcher.spawn(async move {
        _listen_network_status(subscribe_network_type, cloned_folder_manager).await;
    });
}

fn mk_local_server(
    server_config: &ClientServerConfiguration,
) -> (Option<Arc<LocalServer>>, Arc<FlowyWebSocketConnect>) {
    let ws_addr = server_config.ws_addr();
    if cfg!(feature = "http_sync") {
        let ws_conn = Arc::new(FlowyWebSocketConnect::new(ws_addr));
        (None, ws_conn)
    } else {
        let context = flowy_net::local_server::build_server(server_config);
        let local_ws = Arc::new(context.local_ws);
        let ws_conn = Arc::new(FlowyWebSocketConnect::from_local(ws_addr, local_ws));
        (Some(Arc::new(context.local_server)), ws_conn)
    }
}

async fn _listen_user_status(
    config: FlowySDKConfig,
    ws_conn: Arc<FlowyWebSocketConnect>,
    mut subscribe: broadcast::Receiver<UserStatus>,
    document_manager: Arc<DocumentManager>,
    folder_manager: Arc<FolderManager>,
    grid_manager: Arc<GridManager>,
) {
    while let Ok(status) = subscribe.recv().await {
        let result = || async {
            match status {
                UserStatus::Login { token, user_id } => {
                    tracing::trace!("User did login");
                    folder_manager.initialize(&user_id, &token).await?;
                    document_manager.initialize(&user_id).await?;
                    grid_manager.initialize(&user_id, &token).await?;
                    ws_conn.start(token, user_id).await?;
                }
                UserStatus::Logout { token: _, user_id } => {
                    tracing::trace!("User did logout");
                    folder_manager.clear(&user_id).await;
                    ws_conn.stop().await;
                }
                UserStatus::Expired { token: _, user_id } => {
                    tracing::trace!("User session has been expired");
                    folder_manager.clear(&user_id).await;
                    ws_conn.stop().await;
                }
                UserStatus::SignUp { profile, ret } => {
                    tracing::trace!("User did sign up");

                    let view_data_type = match config.document.version {
                        DocumentVersionPB::V0 => ViewDataFormatPB::DeltaFormat,
                        DocumentVersionPB::V1 => ViewDataFormatPB::TreeFormat,
                    };
                    folder_manager
                        .initialize_with_new_user(&profile.id, &profile.token, view_data_type)
                        .await?;
                    document_manager
                        .initialize_with_new_user(&profile.id, &profile.token)
                        .await?;

                    grid_manager
                        .initialize_with_new_user(&profile.id, &profile.token)
                        .await?;

                    ws_conn.start(profile.token.clone(), profile.id.clone()).await?;
                    let _ = ret.send(());
                }
            }
            Ok::<(), FlowyError>(())
        };

        match result().await {
            Ok(_) => {}
            Err(e) => tracing::error!("{}", e),
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
        Ok(_) => {}
        Err(e) => tracing::error!("Init kv store failed: {}", e),
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
    let user_config = UserSessionConfig::new(&config.name, &config.root);
    let cloud_service = UserDepsResolver::resolve(local_server, server_config);
    Arc::new(UserSession::new(user_config, cloud_service))
}
