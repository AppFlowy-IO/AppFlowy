use std::borrow::BorrowMut;
use std::fmt::{Debug, Display};
use std::sync::{Arc, Weak};

use crate::CollabKVDB;
use anyhow::Error;
use arc_swap::{ArcSwap, ArcSwapOption};
use collab::core::collab::DataSource;
use collab::preclude::{Collab, CollabBuilder};
use collab_database::workspace_database::{DatabaseCollabService, WorkspaceDatabase};
use collab_document::blocks::DocumentData;
use collab_document::document::Document;
use collab_entity::{CollabObject, CollabType};
use collab_folder::{Folder, FolderData, FolderNotify};
use collab_plugins::connect_state::{CollabConnectReachability, CollabConnectState};
use collab_plugins::local_storage::kv::snapshot::SnapshotPersistence;
if_native! {
use collab_plugins::local_storage::rocksdb::rocksdb_plugin::{RocksdbBackup, RocksdbDiskPlugin};
}

if_wasm! {
use collab_plugins::local_storage::indexeddb::IndexeddbDiskPlugin;
}

pub use crate::plugin_provider::CollabCloudPluginProvider;
use collab_plugins::local_storage::CollabPersistenceConfig;
use collab_user::core::{UserAwareness, UserAwarenessNotifier};
use tokio::sync::RwLock;

use lib_infra::{if_native, if_wasm};
use tracing::{instrument, trace};

#[derive(Clone, Debug)]
pub enum CollabPluginProviderType {
  Local,
  AppFlowyCloud,
  Supabase,
}

pub enum CollabPluginProviderContext {
  Local,
  AppFlowyCloud {
    uid: i64,
    collab_object: CollabObject,
    local_collab: Weak<RwLock<dyn BorrowMut<Collab> + Send + Sync>>,
  },
  Supabase {
    uid: i64,
    collab_object: CollabObject,
    local_collab_db: Weak<CollabKVDB>,
  },
}

impl Display for CollabPluginProviderContext {
  fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
    let str = match self {
      CollabPluginProviderContext::Local => "Local".to_string(),
      CollabPluginProviderContext::AppFlowyCloud {
        uid: _,
        collab_object,
        ..
      } => collab_object.to_string(),
      CollabPluginProviderContext::Supabase {
        uid: _,
        collab_object,
        local_collab_db: _,
      } => collab_object.to_string(),
    };
    write!(f, "{}", str)
  }
}

pub trait WorkspaceCollabIntegrate: Send + Sync {
  fn workspace_id(&self) -> Result<String, Error>;
  fn device_id(&self) -> Result<String, Error>;
}

pub struct AppFlowyCollabBuilder {
  network_reachability: CollabConnectReachability,
  plugin_provider: ArcSwap<Arc<dyn CollabCloudPluginProvider>>,
  snapshot_persistence: ArcSwapOption<Arc<dyn SnapshotPersistence + 'static>>,
  #[cfg(not(target_arch = "wasm32"))]
  rocksdb_backup: ArcSwapOption<Arc<dyn RocksdbBackup>>,
  workspace_integrate: Arc<dyn WorkspaceCollabIntegrate>,
}

impl AppFlowyCollabBuilder {
  pub fn new(
    storage_provider: impl CollabCloudPluginProvider + 'static,
    workspace_integrate: impl WorkspaceCollabIntegrate + 'static,
  ) -> Self {
    Self {
      network_reachability: CollabConnectReachability::new(),
      plugin_provider: ArcSwap::new(Arc::new(Arc::new(storage_provider))),
      snapshot_persistence: Default::default(),
      #[cfg(not(target_arch = "wasm32"))]
      rocksdb_backup: Default::default(),
      workspace_integrate: Arc::new(workspace_integrate),
    }
  }

  pub fn set_snapshot_persistence(&self, snapshot_persistence: Arc<dyn SnapshotPersistence>) {
    self
      .snapshot_persistence
      .store(Some(snapshot_persistence.into()));
  }

  #[cfg(not(target_arch = "wasm32"))]
  pub fn set_rocksdb_backup(&self, rocksdb_backup: Arc<dyn RocksdbBackup>) {
    self.rocksdb_backup.store(Some(rocksdb_backup.into()));
  }

  pub fn update_network(&self, reachable: bool) {
    if reachable {
      self
        .network_reachability
        .set_state(CollabConnectState::Connected)
    } else {
      self
        .network_reachability
        .set_state(CollabConnectState::Disconnected)
    }
  }

  pub fn collab_object(
    &self,
    workspace_id: &str,
    uid: i64,
    object_id: &str,
    collab_type: CollabType,
  ) -> Result<CollabObject, Error> {
    // Compare the workspace_id with the currently opened workspace_id. Return an error if they do not match.
    // This check is crucial in asynchronous code contexts where the workspace_id might change during operation.
    let actual_workspace_id = self.workspace_integrate.workspace_id()?;
    if workspace_id != actual_workspace_id {
      return Err(anyhow::anyhow!(
        "workspace_id not match when build collab. expect workspace_id: {}, actual workspace_id: {}",
        workspace_id,
        actual_workspace_id
      ));
    }
    let device_id = self.workspace_integrate.device_id()?;
    let workspace_id = self.workspace_integrate.workspace_id()?;
    Ok(CollabObject::new(
      uid,
      object_id.to_string(),
      collab_type,
      workspace_id,
      device_id,
    ))
  }

  #[allow(clippy::too_many_arguments)]
  #[instrument(
    level = "trace",
    skip(self, doc_state, collab_db, builder_config, data)
  )]
  pub fn create_document(
    &self,
    object: CollabObject,
    doc_state: DataSource,
    collab_db: Weak<CollabKVDB>,
    builder_config: CollabBuilderConfig,
    data: Option<DocumentData>,
  ) -> Result<Arc<RwLock<Document>>, Error> {
    assert_eq!(object.collab_type, CollabType::Document);
    let collab = self.build_collab(&object, &collab_db, doc_state)?;
    let document = Document::open_with(collab, data)?;
    let document = Arc::new(RwLock::new(document));
    self.finalize(object, builder_config, collab_db, document)
  }

  #[allow(clippy::too_many_arguments)]
  #[instrument(
    level = "trace",
    skip(self, object, doc_state, collab_db, builder_config, folder_notifier)
  )]
  pub fn create_folder(
    &self,
    object: CollabObject,
    doc_state: DataSource,
    collab_db: Weak<CollabKVDB>,
    builder_config: CollabBuilderConfig,
    folder_notifier: Option<FolderNotify>,
    folder_data: Option<FolderData>,
  ) -> Result<Arc<RwLock<Folder>>, Error> {
    assert_eq!(object.collab_type, CollabType::Folder);
    let collab = self.build_collab(&object, &collab_db, doc_state)?;
    let folder = Folder::open_with(object.uid, collab, folder_notifier, folder_data);
    let folder = Arc::new(RwLock::new(folder));
    self.finalize(object, builder_config, collab_db, folder)
  }

  #[allow(clippy::too_many_arguments)]
  #[instrument(
    level = "trace",
    skip(self, object, doc_state, collab_db, builder_config, notifier)
  )]
  pub fn create_user_awareness(
    &self,
    object: CollabObject,
    doc_state: DataSource,
    collab_db: Weak<CollabKVDB>,
    builder_config: CollabBuilderConfig,
    notifier: Option<UserAwarenessNotifier>,
  ) -> Result<Arc<RwLock<UserAwareness>>, Error> {
    assert_eq!(object.collab_type, CollabType::UserAwareness);
    let collab = self.build_collab(&object, &collab_db, doc_state)?;
    let user_awareness = UserAwareness::open(collab, notifier);
    let user_awareness = Arc::new(RwLock::new(user_awareness));
    self.finalize(object, builder_config, collab_db, user_awareness)
  }

  #[allow(clippy::too_many_arguments)]
  #[instrument(
    level = "trace",
    skip(self, object, doc_state, collab_db, builder_config, collab_service)
  )]
  pub fn create_workspace(
    &self,
    object: CollabObject,
    doc_state: DataSource,
    collab_db: Weak<CollabKVDB>,
    builder_config: CollabBuilderConfig,
    collab_service: impl DatabaseCollabService,
  ) -> Result<Arc<RwLock<WorkspaceDatabase>>, Error> {
    assert_eq!(object.collab_type, CollabType::WorkspaceDatabase);
    let persistence_config = CollabPersistenceConfig::default();
    let collab = self.build_collab(&object, &collab_db, doc_state)?;
    let workspace = WorkspaceDatabase::open(
      object.uid,
      collab,
      collab_db.clone(),
      persistence_config,
      collab_service,
    );
    let workspace = Arc::new(RwLock::new(workspace));
    self.finalize(object, builder_config, collab_db, workspace)
  }

  pub fn build_collab(
    &self,
    object: &CollabObject,
    collab_db: &Weak<CollabKVDB>,
    collab_doc_state: DataSource,
  ) -> Result<Collab, Error> {
    let collab = CollabBuilder::new(object.uid, &object.object_id)
      .with_doc_state(collab_doc_state)
      .with_device_id(self.workspace_integrate.device_id()?)
      .build()?;

    let persistence_config = CollabPersistenceConfig::default();
    #[cfg(target_arch = "wasm32")]
    {
      collab.add_plugin(Box::new(IndexeddbDiskPlugin::new(
        uid,
        object_id.to_string(),
        object_type.clone(),
        collab_db.clone(),
      )));
    }

    #[cfg(not(target_arch = "wasm32"))]
    {
      collab.add_plugin(Box::new(RocksdbDiskPlugin::new_with_config(
        object.uid,
        object.object_id.to_string(),
        object.collab_type.clone(),
        collab_db.clone(),
        persistence_config.clone(),
        None,
      )));
    }
    Ok(collab)
  }

  pub fn finalize<T>(
    &self,
    object: CollabObject,
    build_config: CollabBuilderConfig,
    collab_db: Weak<CollabKVDB>,
    collab: Arc<RwLock<T>>,
  ) -> Result<Arc<RwLock<T>>, Error>
  where
    T: BorrowMut<Collab> + Send + Sync + 'static,
  {
    if build_config.sync_enable {
      let plugin_provider = self.plugin_provider.load_full();
      let provider_type = plugin_provider.provider_type();
      let span =
        tracing::span!(tracing::Level::TRACE, "collab_builder", object_id = %object.object_id);
      let _enter = span.enter();
      match provider_type {
        CollabPluginProviderType::AppFlowyCloud => {
          let local_collab = Arc::downgrade(&collab);
          let plugins = plugin_provider.get_plugins(CollabPluginProviderContext::AppFlowyCloud {
            uid: object.uid,
            collab_object: object,
            local_collab,
          });

          // at the moment when we get the lock, the collab object is not yet exposed outside
          let collab = collab.try_read().unwrap();
          let collab = collab.borrow();
          for plugin in plugins {
            collab.add_plugin(plugin);
          }
        },
        CollabPluginProviderType::Supabase => {
          #[cfg(not(target_arch = "wasm32"))]
          {
            trace!("init supabase collab plugins");
            let local_collab_db = collab_db.clone();
            let plugins = plugin_provider.get_plugins(CollabPluginProviderContext::Supabase {
              uid: object.uid,
              collab_object: object,
              local_collab_db,
            });
            // at the moment when we get the lock, the collab object is not yet exposed outside
            let collab = collab.try_read().unwrap();
            let collab = collab.borrow();
            for plugin in plugins {
              collab.add_plugin(plugin);
            }
          }
        },
        CollabPluginProviderType::Local => {},
      }
    }

    if build_config.auto_initialize {
      // at the moment when we get the lock, the collab object is not yet exposed outside
      let mut collab = collab.try_write().unwrap();
      let collab = (*collab).borrow_mut();
      collab.initialize();
    }
    trace!("collab initialized");
    Ok(collab)
  }
}

pub struct CollabBuilderConfig {
  pub sync_enable: bool,
  /// If auto_initialize is false, the collab object will not be initialized automatically.
  /// You need to call collab.initialize() manually.
  ///
  /// Default is true.
  pub auto_initialize: bool,
}

impl Default for CollabBuilderConfig {
  fn default() -> Self {
    Self {
      sync_enable: true,
      auto_initialize: true,
    }
  }
}

impl CollabBuilderConfig {
  pub fn sync_enable(mut self, sync_enable: bool) -> Self {
    self.sync_enable = sync_enable;
    self
  }

  pub fn auto_initialize(mut self, auto_initialize: bool) -> Self {
    self.auto_initialize = auto_initialize;
    self
  }
}
