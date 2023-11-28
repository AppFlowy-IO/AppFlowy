#![allow(unused_doc_comments)]

use std::sync::Arc;
use std::sync::Weak;
use std::time::Duration;

use tokio::sync::RwLock;
use tracing::{debug, error, event, info, instrument};

use collab_integrate::collab_builder::{AppFlowyCollabBuilder, CollabDataSource};
use flowy_database2::DatabaseManager;
use flowy_document2::manager::DocumentManager;
use flowy_folder2::manager::FolderManager;
use flowy_sqlite::kv::StorePreferences;
use flowy_storage::FileStorageService;
use flowy_task::{TaskDispatcher, TaskRunner};
use flowy_user::event_map::UserCloudServiceProvider;
use flowy_user::manager::{UserConfig, UserManager};
use lib_dispatch::prelude::*;
use lib_dispatch::runtime::AFPluginRuntime;
use module::make_plugins;
pub use module::*;

use crate::config::AppFlowyCoreConfig;
use crate::deps_resolve::collab_backup::RocksdbBackupImpl;
use crate::deps_resolve::*;
use crate::integrate::collab_interact::CollabInteractImpl;
use crate::integrate::log::init_log;
use crate::integrate::server::{current_server_type, ServerProvider, ServerType};
use crate::integrate::user::UserStatusCallbackImpl;

pub mod config;
mod deps_resolve;
mod integrate;
pub mod module;

/// This name will be used as to identify the current [AppFlowyCore] instance.
/// Don't change this.
pub const DEFAULT_NAME: &str = "appflowy";

#[derive(Clone)]
pub struct AppFlowyCore {
  #[allow(dead_code)]
  pub config: AppFlowyCoreConfig,
  pub user_manager: Arc<UserManager>,
  pub document_manager: Arc<DocumentManager>,
  pub folder_manager: Arc<FolderManager>,
  pub database_manager: Arc<DatabaseManager>,
  pub event_dispatcher: Arc<AFPluginDispatcher>,
  pub server_provider: Arc<ServerProvider>,
  pub task_dispatcher: Arc<RwLock<TaskDispatcher>>,
  pub store_preference: Arc<StorePreferences>,
}

impl AppFlowyCore {
  #[cfg(feature = "single_thread")]
  pub async fn new(config: AppFlowyCoreConfig) -> Self {
    let runtime = Arc::new(AFPluginRuntime::new().unwrap());
    Self::init(config, runtime).await
  }

  #[cfg(not(feature = "single_thread"))]
  pub fn new(config: AppFlowyCoreConfig) -> Self {
    let runtime = Arc::new(AFPluginRuntime::new().unwrap());
    let cloned_runtime = runtime.clone();
    runtime.block_on(Self::init(config, cloned_runtime))
  }

  #[instrument(skip(config, runtime))]
  async fn init(config: AppFlowyCoreConfig, runtime: Arc<AFPluginRuntime>) -> Self {
    #[allow(clippy::if_same_then_else)]
    if cfg!(debug_assertions) {
      /// The profiling can be used to tracing the performance of the application.
      /// Check out the [Link](https://appflowy.gitbook.io/docs/essential-documentation/contribute-to-appflowy/architecture/backend/profiling)
      ///  for more information.
      #[cfg(feature = "profiling")]
      console_subscriber::init();

      // Init the logger before anything else
      #[cfg(not(feature = "profiling"))]
      init_log(&config);
    } else {
      init_log(&config);
    }

    // Init the key value database
    let store_preference = Arc::new(StorePreferences::new(&config.storage_path).unwrap());
    info!("🔥{:?}", &config);
    let task_scheduler = TaskDispatcher::new(Duration::from_secs(2));
    let task_dispatcher = Arc::new(RwLock::new(task_scheduler));
    runtime.spawn(TaskRunner::run(task_dispatcher.clone()));

    let server_type = current_server_type(&store_preference);
    debug!("🔥runtime:{}, server:{}", runtime, server_type);
    let server_provider = Arc::new(ServerProvider::new(
      config.clone(),
      server_type,
      Arc::downgrade(&store_preference),
    ));

    event!(tracing::Level::DEBUG, "Init managers",);
    let (
      user_manager,
      folder_manager,
      server_provider,
      database_manager,
      document_manager,
      collab_builder,
    ) = async {
      /// The shared collab builder is used to build the [Collab] instance. The plugins will be loaded
      /// on demand based on the [CollabPluginConfig].
      let collab_builder = Arc::new(AppFlowyCollabBuilder::new(
        server_provider.clone(),
        config.device_id.clone(),
      ));
      let user_manager = init_user_manager(
        &config,
        &store_preference,
        server_provider.clone(),
        Arc::downgrade(&collab_builder),
      );

      collab_builder
        .set_snapshot_persistence(Arc::new(SnapshotDBImpl(Arc::downgrade(&user_manager))));

      collab_builder.set_rocksdb_backup(Arc::new(RocksdbBackupImpl(Arc::downgrade(&user_manager))));

      let database_manager = DatabaseDepsResolver::resolve(
        Arc::downgrade(&user_manager),
        task_dispatcher.clone(),
        collab_builder.clone(),
        server_provider.clone(),
      )
      .await;

      let document_manager = DocumentDepsResolver::resolve(
        Arc::downgrade(&user_manager),
        &database_manager,
        collab_builder.clone(),
        server_provider.clone(),
        Arc::downgrade(&(server_provider.clone() as Arc<dyn FileStorageService>)),
      );

      let folder_manager = FolderDepsResolver::resolve(
        Arc::downgrade(&user_manager),
        &document_manager,
        &database_manager,
        collab_builder.clone(),
        server_provider.clone(),
      )
      .await;

      (
        user_manager,
        folder_manager,
        server_provider,
        database_manager,
        document_manager,
        collab_builder,
      )
    }
    .await;

    let user_status_callback = UserStatusCallbackImpl {
      collab_builder,
      folder_manager: folder_manager.clone(),
      database_manager: database_manager.clone(),
      document_manager: document_manager.clone(),
      server_provider: server_provider.clone(),
      config: config.clone(),
    };

    let collab_interact_impl = CollabInteractImpl {
      database_manager: Arc::downgrade(&database_manager),
      document_manager: Arc::downgrade(&document_manager),
    };

    let cloned_user_manager = Arc::downgrade(&user_manager);
    if let Some(user_manager) = cloned_user_manager.upgrade() {
      if let Err(err) = user_manager
        .init(user_status_callback, collab_interact_impl)
        .await
      {
        error!("Init user failed: {}", err)
      }
    }
    let event_dispatcher = Arc::new(AFPluginDispatcher::construct(runtime, || {
      make_plugins(
        Arc::downgrade(&folder_manager),
        Arc::downgrade(&database_manager),
        Arc::downgrade(&user_manager),
        Arc::downgrade(&document_manager),
      )
    }));

    Self {
      config,
      user_manager,
      document_manager,
      folder_manager,
      database_manager,
      event_dispatcher,
      server_provider,
      task_dispatcher,
      store_preference,
    }
  }

  /// Only expose the dispatcher in test
  pub fn dispatcher(&self) -> Arc<AFPluginDispatcher> {
    self.event_dispatcher.clone()
  }
}

fn init_user_manager(
  config: &AppFlowyCoreConfig,
  storage_preference: &Arc<StorePreferences>,
  user_cloud_service_provider: Arc<dyn UserCloudServiceProvider>,
  collab_builder: Weak<AppFlowyCollabBuilder>,
) -> Arc<UserManager> {
  let user_config = UserConfig::new(
    &config.name,
    &config.storage_path,
    &config.application_path,
    &config.device_id,
  );
  UserManager::new(
    user_config,
    user_cloud_service_provider,
    storage_preference.clone(),
    collab_builder,
  )
}

impl From<ServerType> for CollabDataSource {
  fn from(server_type: ServerType) -> Self {
    match server_type {
      ServerType::Local => CollabDataSource::Local,
      ServerType::AFCloud => CollabDataSource::AppFlowyCloud,
      ServerType::Supabase => CollabDataSource::Supabase,
    }
  }
}
