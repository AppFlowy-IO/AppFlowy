#![allow(unused_doc_comments)]

use std::str::FromStr;
use std::time::Duration;
use std::{
  fmt,
  sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
  },
};

use appflowy_integrate::collab_builder::AppFlowyCollabBuilder;
use appflowy_integrate::config::{AWSDynamoDBConfig, AppFlowyCollabConfig};
use tokio::sync::RwLock;

use flowy_database2::DatabaseManager2;
use flowy_document2::manager::DocumentManager as DocumentManager2;
use flowy_error::FlowyResult;
use flowy_folder2::manager::Folder2Manager;
use flowy_sqlite::kv::KV;
use flowy_task::{TaskDispatcher, TaskRunner};
use flowy_user::entities::UserProfile;
use flowy_user::event_map::{UserCloudServiceProvider, UserStatusCallback};
use flowy_user::services::{UserSession, UserSessionConfig};
use lib_dispatch::prelude::*;
use lib_dispatch::runtime::tokio_default_runtime;
use lib_infra::future::{to_fut, Fut};
use module::make_plugins;
pub use module::*;

use crate::deps_resolve::*;
use crate::integrate::server::AppFlowyServerProvider;

mod deps_resolve;
mod integrate;
pub mod module;

static INIT_LOG: AtomicBool = AtomicBool::new(false);

/// This name will be used as to identify the current [AppFlowyCore] instance.
/// Don't change this.
pub const DEFAULT_NAME: &str = "appflowy";

#[derive(Clone)]
pub struct AppFlowyCoreConfig {
  /// Different `AppFlowyCoreConfig` instance should have different name
  name: String,
  /// Panics if the `root` path is not existing
  storage_path: String,
  log_filter: String,
}

impl fmt::Debug for AppFlowyCoreConfig {
  fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
    f.debug_struct("AppFlowyCoreConfig")
      .field("storage_path", &self.storage_path)
      .finish()
  }
}

impl AppFlowyCoreConfig {
  pub fn new(root: &str, name: String) -> Self {
    AppFlowyCoreConfig {
      name,
      storage_path: root.to_owned(),
      log_filter: create_log_filter("info".to_owned(), vec![]),
    }
  }

  pub fn log_filter(mut self, level: &str, with_crates: Vec<String>) -> Self {
    self.log_filter = create_log_filter(level.to_owned(), with_crates);
    self
  }
}

fn create_log_filter(level: String, with_crates: Vec<String>) -> String {
  let level = std::env::var("RUST_LOG").unwrap_or(level);
  let mut filters = with_crates
    .into_iter()
    .map(|crate_name| format!("{}={}", crate_name, level))
    .collect::<Vec<String>>();
  filters.push(format!("flowy_core={}", level));
  filters.push(format!("flowy_folder2={}", level));
  filters.push(format!("collab_folder={}", level));
  // filters.push(format!("collab_persistence={}", level));
  filters.push(format!("collab_database={}", level));
  filters.push(format!("collab_plugins={}", level));
  filters.push(format!("appflowy_integrate={}", level));
  filters.push(format!("collab={}", level));
  filters.push(format!("flowy_user={}", level));
  filters.push(format!("flowy_document2={}", level));
  filters.push(format!("flowy_database2={}", level));
  filters.push(format!("flowy_notification={}", "info"));
  filters.push(format!("lib_ot={}", level));
  filters.push(format!("lib_infra={}", level));
  filters.push(format!("flowy_task={}", level));
  // filters.push(format!("lib_dispatch={}", level));

  filters.push(format!("dart_ffi={}", "info"));
  filters.push(format!("flowy_sqlite={}", "info"));
  filters.push(format!("flowy_net={}", level));
  #[cfg(feature = "profiling")]
  filters.push(format!("tokio={}", level));

  #[cfg(feature = "profiling")]
  filters.push(format!("runtime={}", level));

  filters.join(",")
}

#[derive(Clone)]
pub struct AppFlowyCore {
  #[allow(dead_code)]
  pub config: AppFlowyCoreConfig,
  pub user_session: Arc<UserSession>,
  pub document_manager2: Arc<DocumentManager2>,
  pub folder_manager: Arc<Folder2Manager>,
  pub database_manager: Arc<DatabaseManager2>,
  pub event_dispatcher: Arc<AFPluginDispatcher>,
  pub server_provider: Arc<AppFlowyServerProvider>,
  pub task_dispatcher: Arc<RwLock<TaskDispatcher>>,
}

impl AppFlowyCore {
  pub fn new(config: AppFlowyCoreConfig) -> Self {
    /// The profiling can be used to tracing the performance of the application.
    /// Check out the [Link](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/backend/profiling)
    ///  for more information.
    #[cfg(feature = "profiling")]
    console_subscriber::init();

    // Init the logger before anything else
    init_log(&config);

    // Init the key value database
    init_kv(&config.storage_path);

    // The collab config is used to build the [Collab] instance that used in document,
    // database, folder, etc.
    let collab_config = get_collab_config();
    inject_aws_env(collab_config.aws_config());

    /// The shared collab builder is used to build the [Collab] instance. The plugins will be loaded
    /// on demand based on the [AppFlowyCollabConfig].
    let collab_builder = Arc::new(AppFlowyCollabBuilder::new(collab_config));

    tracing::debug!("🔥 {:?}", config);
    let runtime = tokio_default_runtime().unwrap();
    let task_scheduler = TaskDispatcher::new(Duration::from_secs(2));
    let task_dispatcher = Arc::new(RwLock::new(task_scheduler));
    runtime.spawn(TaskRunner::run(task_dispatcher.clone()));

    let server_provider = Arc::new(AppFlowyServerProvider::new());
    let (user_session, folder_manager, server_provider, database_manager, document_manager2) =
      runtime.block_on(async {
        let user_session = mk_user_session(&config, server_provider.clone());
        let database_manager2 = Database2DepsResolver::resolve(
          user_session.clone(),
          task_dispatcher.clone(),
          collab_builder.clone(),
        )
        .await;

        let document_manager2 = Document2DepsResolver::resolve(
          user_session.clone(),
          &database_manager2,
          collab_builder.clone(),
        );

        let folder_manager = Folder2DepsResolver::resolve(
          user_session.clone(),
          &document_manager2,
          &database_manager2,
          collab_builder.clone(),
        )
        .await;

        (
          user_session,
          folder_manager,
          server_provider,
          database_manager2,
          document_manager2,
        )
      });

    let user_status_listener = UserStatusListener {
      folder_manager: folder_manager.clone(),
      database_manager: database_manager.clone(),
      config: config.clone(),
    };

    let user_status_callback = UserStatusCallbackImpl {
      listener: Arc::new(user_status_listener),
    };

    let cloned_user_session = user_session.clone();
    runtime.block_on(async move {
      cloned_user_session.clone().init(user_status_callback).await;
    });

    let event_dispatcher = Arc::new(AFPluginDispatcher::construct(runtime, || {
      make_plugins(
        &folder_manager,
        &database_manager,
        &user_session,
        &document_manager2,
      )
    }));

    Self {
      config,
      user_session,
      document_manager2,
      folder_manager,
      database_manager,
      event_dispatcher,
      server_provider,
      task_dispatcher,
    }
  }

  pub fn dispatcher(&self) -> Arc<AFPluginDispatcher> {
    self.event_dispatcher.clone()
  }
}

fn init_kv(root: &str) {
  match KV::init(root) {
    Ok(_) => {},
    Err(e) => tracing::error!("Init kv store failed: {}", e),
  }
}

fn get_collab_config() -> AppFlowyCollabConfig {
  match KV::get_str("collab_config") {
    None => AppFlowyCollabConfig::default(),
    Some(s) => AppFlowyCollabConfig::from_str(&s).unwrap_or_default(),
  }
}

fn inject_aws_env(aws_config: Option<&AWSDynamoDBConfig>) {
  if let Some(aws_config) = aws_config {
    std::env::set_var("AWS_ACCESS_KEY_ID", aws_config.access_key_id.clone());
    std::env::set_var(
      "AWS_SECRET_ACCESS_KEY",
      aws_config.secret_access_key.clone(),
    );
  }
}

fn init_log(config: &AppFlowyCoreConfig) {
  if !INIT_LOG.load(Ordering::SeqCst) {
    INIT_LOG.store(true, Ordering::SeqCst);

    let _ = lib_log::Builder::new("AppFlowy-Client", &config.storage_path)
      .env_filter(&config.log_filter)
      .build();
  }
}

fn mk_user_session(
  config: &AppFlowyCoreConfig,
  user_cloud_service_provider: Arc<dyn UserCloudServiceProvider>,
) -> Arc<UserSession> {
  let user_config = UserSessionConfig::new(&config.name, &config.storage_path);
  Arc::new(UserSession::new(user_config, user_cloud_service_provider))
}

struct UserStatusListener {
  folder_manager: Arc<Folder2Manager>,
  database_manager: Arc<DatabaseManager2>,
  #[allow(dead_code)]
  config: AppFlowyCoreConfig,
}

impl UserStatusListener {
  async fn did_sign_in(&self, user_id: i64, workspace_id: String) -> FlowyResult<()> {
    self
      .folder_manager
      .initialize(user_id, workspace_id)
      .await?;
    self.database_manager.initialize(user_id).await?;
    Ok(())
  }

  async fn did_sign_up(&self, user_profile: &UserProfile) -> FlowyResult<()> {
    self
      .folder_manager
      .initialize_with_new_user(user_profile.id, &user_profile.token)
      .await?;

    self
      .database_manager
      .initialize_with_new_user(user_profile.id, &user_profile.token)
      .await?;

    Ok(())
  }

  async fn did_expired(&self, _token: &str, user_id: i64) -> FlowyResult<()> {
    self.folder_manager.clear(user_id).await;
    Ok(())
  }
}

struct UserStatusCallbackImpl {
  listener: Arc<UserStatusListener>,
}

impl UserStatusCallback for UserStatusCallbackImpl {
  fn did_sign_in(&self, user_id: i64) -> Fut<FlowyResult<()>> {
    let listener = self.listener.clone();
    let user_id = user_id.to_owned();
    to_fut(async move { listener.did_sign_in(user_id).await })
  }

  fn did_sign_up(&self, user_profile: &UserProfile) -> Fut<FlowyResult<()>> {
    let listener = self.listener.clone();
    let user_profile = user_profile.clone();
    to_fut(async move { listener.did_sign_up(&user_profile).await })
  }

  fn did_expired(&self, token: &str, user_id: i64) -> Fut<FlowyResult<()>> {
    let listener = self.listener.clone();
    let token = token.to_owned();
    let user_id = user_id.to_owned();
    to_fut(async move { listener.did_expired(&token, user_id).await })
  }
}
