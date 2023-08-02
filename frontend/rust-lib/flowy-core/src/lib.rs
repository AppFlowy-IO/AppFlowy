#![allow(unused_doc_comments)]

use std::time::Duration;
use std::{
  fmt,
  sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
  },
};

use appflowy_integrate::collab_builder::{AppFlowyCollabBuilder, CollabStorageType};
use tokio::sync::RwLock;

use flowy_database2::DatabaseManager;
use flowy_document2::manager::DocumentManager;
use flowy_error::FlowyResult;
use flowy_folder2::manager::{FolderInitializeData, FolderManager};
use flowy_sqlite::kv::KV;
use flowy_task::{TaskDispatcher, TaskRunner};
use flowy_user::event_map::{SignUpContext, UserCloudServiceProvider, UserStatusCallback};
use flowy_user::services::{get_supabase_config, UserSession, UserSessionConfig};
use flowy_user_deps::entities::{AuthType, UserProfile, UserWorkspace};
use lib_dispatch::prelude::*;
use lib_dispatch::runtime::tokio_default_runtime;
use lib_infra::future::{to_fut, Fut};
use module::make_plugins;
pub use module::*;

use crate::deps_resolve::*;
use crate::integrate::server::{AppFlowyServerProvider, ServerProviderType};

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
  pub storage_path: String,
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
  filters.push(format!("collab_sync={}", level));
  filters.push(format!("collab_folder={}", level));
  filters.push(format!("collab_persistence={}", level));
  filters.push(format!("collab_database={}", level));
  filters.push(format!("collab_plugins={}", level));
  filters.push(format!("appflowy_integrate={}", level));
  filters.push(format!("collab={}", level));
  filters.push(format!("flowy_user={}", level));
  filters.push(format!("flowy_document2={}", level));
  filters.push(format!("flowy_database2={}", level));
  filters.push(format!("flowy_server={}", level));
  filters.push(format!("flowy_notification={}", "info"));
  filters.push(format!("lib_infra={}", level));
  filters.push(format!("flowy_task={}", level));

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
  pub document_manager: Arc<DocumentManager>,
  pub folder_manager: Arc<FolderManager>,
  pub database_manager: Arc<DatabaseManager>,
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

    tracing::info!("🔥 {:?}", &config);
    let runtime = tokio_default_runtime().unwrap();
    let task_scheduler = TaskDispatcher::new(Duration::from_secs(2));
    let task_dispatcher = Arc::new(RwLock::new(task_scheduler));
    runtime.spawn(TaskRunner::run(task_dispatcher.clone()));

    let server_provider = Arc::new(AppFlowyServerProvider::new(
      config.clone(),
      get_supabase_config(),
    ));

    let (
      user_session,
      folder_manager,
      server_provider,
      database_manager,
      document_manager,
      collab_builder,
    ) = runtime.block_on(async {
      let user_session = mk_user_session(&config, server_provider.clone());
      /// The shared collab builder is used to build the [Collab] instance. The plugins will be loaded
      /// on demand based on the [CollabPluginConfig].
      let collab_builder = Arc::new(AppFlowyCollabBuilder::new(
        server_provider.clone(),
        Some(Arc::new(SnapshotDBImpl(Arc::downgrade(&user_session)))),
      ));

      let database_manager = DatabaseDepsResolver::resolve(
        Arc::downgrade(&user_session),
        task_dispatcher.clone(),
        collab_builder.clone(),
        server_provider.clone(),
      )
      .await;

      let document_manager = DocumentDepsResolver::resolve(
        Arc::downgrade(&user_session),
        &database_manager,
        collab_builder.clone(),
        server_provider.clone(),
      );

      let folder_manager = FolderDepsResolver::resolve(
        Arc::downgrade(&user_session),
        &document_manager,
        &database_manager,
        collab_builder.clone(),
        server_provider.clone(),
      )
      .await;

      (
        user_session,
        folder_manager,
        server_provider,
        database_manager,
        document_manager,
        collab_builder,
      )
    });

    let user_status_listener = UserStatusCallbackImpl {
      collab_builder,
      folder_manager: folder_manager.clone(),
      database_manager: database_manager.clone(),
      document_manager: document_manager.clone(),
      config: config.clone(),
    };

    let cloned_user_session = Arc::downgrade(&user_session);
    runtime.block_on(async move {
      if let Some(user_session) = cloned_user_session.upgrade() {
        user_session.init(user_status_listener).await;
      }
    });

    let event_dispatcher = Arc::new(AFPluginDispatcher::construct(runtime, || {
      make_plugins(
        Arc::downgrade(&folder_manager),
        Arc::downgrade(&database_manager),
        Arc::downgrade(&user_session),
        Arc::downgrade(&document_manager),
      )
    }));

    Self {
      config,
      user_session,
      document_manager,
      folder_manager,
      database_manager,
      event_dispatcher,
      server_provider,
      task_dispatcher,
    }
  }

  /// Only expose the dispatcher in test
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

struct UserStatusCallbackImpl {
  collab_builder: Arc<AppFlowyCollabBuilder>,
  folder_manager: Arc<FolderManager>,
  database_manager: Arc<DatabaseManager>,
  document_manager: Arc<DocumentManager>,
  #[allow(dead_code)]
  config: AppFlowyCoreConfig,
}

impl UserStatusCallback for UserStatusCallbackImpl {
  fn auth_type_did_changed(&self, _auth_type: AuthType) {}

  fn did_init(&self, user_id: i64, user_workspace: &UserWorkspace) -> Fut<FlowyResult<()>> {
    let user_id = user_id.to_owned();
    let user_workspace = user_workspace.clone();
    let collab_builder = self.collab_builder.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let document_manager = self.document_manager.clone();

    to_fut(async move {
      collab_builder.initialize(user_workspace.id.clone());
      folder_manager
        .initialize(user_id, &user_workspace.id, FolderInitializeData::Empty)
        .await?;
      database_manager
        .initialize(
          user_id,
          user_workspace.id.clone(),
          user_workspace.database_storage_id,
        )
        .await?;
      document_manager
        .initialize(user_id, user_workspace.id)
        .await?;
      Ok(())
    })
  }

  fn did_sign_in(&self, user_id: i64, user_workspace: &UserWorkspace) -> Fut<FlowyResult<()>> {
    let user_id = user_id.to_owned();
    let user_workspace = user_workspace.clone();
    let collab_builder = self.collab_builder.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let document_manager = self.document_manager.clone();

    to_fut(async move {
      collab_builder.initialize(user_workspace.id.clone());
      folder_manager
        .initialize_with_workspace_id(user_id, &user_workspace.id)
        .await?;
      database_manager
        .initialize(
          user_id,
          user_workspace.id.clone(),
          user_workspace.database_storage_id,
        )
        .await?;
      document_manager
        .initialize(user_id, user_workspace.id)
        .await?;
      Ok(())
    })
  }

  fn did_sign_up(
    &self,
    context: SignUpContext,
    user_profile: &UserProfile,
    user_workspace: &UserWorkspace,
  ) -> Fut<FlowyResult<()>> {
    let user_profile = user_profile.clone();
    let collab_builder = self.collab_builder.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let user_workspace = user_workspace.clone();
    let document_manager = self.document_manager.clone();
    to_fut(async move {
      collab_builder.initialize(user_workspace.id.clone());
      folder_manager
        .initialize_with_new_user(
          user_profile.id,
          &user_profile.token,
          context.is_new,
          context.local_folder,
          &user_workspace.id,
        )
        .await?;
      database_manager
        .initialize_with_new_user(
          user_profile.id,
          user_workspace.id.clone(),
          user_workspace.database_storage_id,
        )
        .await?;

      document_manager
        .initialize_with_new_user(user_profile.id, user_workspace.id)
        .await?;
      Ok(())
    })
  }

  fn did_expired(&self, _token: &str, user_id: i64) -> Fut<FlowyResult<()>> {
    let folder_manager = self.folder_manager.clone();
    to_fut(async move {
      folder_manager.clear(user_id).await;
      Ok(())
    })
  }

  fn open_workspace(&self, user_id: i64, user_workspace: &UserWorkspace) -> Fut<FlowyResult<()>> {
    let user_workspace = user_workspace.clone();
    let collab_builder = self.collab_builder.clone();
    let folder_manager = self.folder_manager.clone();
    let database_manager = self.database_manager.clone();
    let document_manager = self.document_manager.clone();

    to_fut(async move {
      collab_builder.initialize(user_workspace.id.clone());
      folder_manager
        .initialize_with_workspace_id(user_id, &user_workspace.id)
        .await?;

      database_manager
        .initialize(
          user_id,
          user_workspace.id.clone(),
          user_workspace.database_storage_id,
        )
        .await?;
      document_manager
        .initialize(user_id, user_workspace.id)
        .await?;
      Ok(())
    })
  }

  fn did_update_network(&self, reachable: bool) {
    self.collab_builder.update_network(reachable);
  }
}

impl From<ServerProviderType> for CollabStorageType {
  fn from(server_provider: ServerProviderType) -> Self {
    match server_provider {
      ServerProviderType::Local => CollabStorageType::Local,
      ServerProviderType::SelfHosted => CollabStorageType::Local,
      ServerProviderType::Supabase => CollabStorageType::Supabase,
    }
  }
}
