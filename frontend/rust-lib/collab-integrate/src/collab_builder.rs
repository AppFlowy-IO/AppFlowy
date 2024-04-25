use std::fmt::{Debug, Display};
use std::sync::{Arc, Weak};

use crate::CollabKVDB;
use anyhow::Error;
use collab::core::collab::{DataSource, MutexCollab};
use collab::preclude::CollabBuilder;
use collab_entity::{CollabObject, CollabType};
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

use lib_infra::{if_native, if_wasm};
use parking_lot::{Mutex, RwLock};
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
    local_collab: Weak<MutexCollab>,
  },
  Supabase {
    uid: i64,
    collab_object: CollabObject,
    local_collab: Weak<MutexCollab>,
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
        local_collab: _,
      } => collab_object.to_string(),
      CollabPluginProviderContext::Supabase {
        uid: _,
        collab_object,
        local_collab: _,
        local_collab_db: _,
      } => collab_object.to_string(),
    };
    write!(f, "{}", str)
  }
}

pub trait WorkspaceCollabIntegrate: Send + Sync {
  fn workspace_id(&self) -> Result<String, Error>;
  fn device_id(&self) -> String;
}

pub struct AppFlowyCollabBuilder {
  network_reachability: CollabConnectReachability,
  plugin_provider: RwLock<Arc<dyn CollabCloudPluginProvider>>,
  snapshot_persistence: Mutex<Option<Arc<dyn SnapshotPersistence>>>,
  #[cfg(not(target_arch = "wasm32"))]
  rocksdb_backup: Mutex<Option<Arc<dyn RocksdbBackup>>>,
  workspace_integrate: Arc<dyn WorkspaceCollabIntegrate>,
}

impl AppFlowyCollabBuilder {
  pub fn new(
    storage_provider: impl CollabCloudPluginProvider + 'static,
    workspace_integrate: impl WorkspaceCollabIntegrate + 'static,
  ) -> Self {
    Self {
      network_reachability: CollabConnectReachability::new(),
      plugin_provider: RwLock::new(Arc::new(storage_provider)),
      snapshot_persistence: Default::default(),
      #[cfg(not(target_arch = "wasm32"))]
      rocksdb_backup: Default::default(),
      workspace_integrate: Arc::new(workspace_integrate),
    }
  }

  pub fn set_snapshot_persistence(&self, snapshot_persistence: Arc<dyn SnapshotPersistence>) {
    *self.snapshot_persistence.lock() = Some(snapshot_persistence);
  }

  #[cfg(not(target_arch = "wasm32"))]
  pub fn set_rocksdb_backup(&self, rocksdb_backup: Arc<dyn RocksdbBackup>) {
    *self.rocksdb_backup.lock() = Some(rocksdb_backup);
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

  fn collab_object(
    &self,
    uid: i64,
    object_id: &str,
    collab_type: CollabType,
  ) -> Result<CollabObject, Error> {
    let device_id = self.workspace_integrate.device_id();
    let workspace_id = self.workspace_integrate.workspace_id()?;
    Ok(CollabObject::new(
      uid,
      object_id.to_string(),
      collab_type,
      workspace_id,
      device_id,
    ))
  }

  /// Creates a new collaboration builder with the default configuration.
  ///
  /// This function will initiate the creation of a [MutexCollab] object if it does not already exist.
  /// To check for the existence of the object prior to creation, you should utilize a transaction
  /// returned by the [read_txn] method of the [CollabKVDB]. Then, invoke the [is_exist] method
  /// to confirm the object's presence.
  ///
  /// # Parameters
  /// - `uid`: The user ID associated with the collaboration.
  /// - `object_id`: A string reference representing the ID of the object.
  /// - `object_type`: The type of the collaboration, defined by the [CollabType] enum.
  /// - `raw_data`: The raw data of the collaboration object, defined by the [CollabDocState] type.
  /// - `collab_db`: A weak reference to the [CollabKVDB].
  ///
  pub async fn build(
    &self,
    uid: i64,
    object_id: &str,
    object_type: CollabType,
    collab_doc_state: DataSource,
    collab_db: Weak<CollabKVDB>,
    build_config: CollabBuilderConfig,
  ) -> Result<Arc<MutexCollab>, Error> {
    let persistence_config = CollabPersistenceConfig::default();
    self.build_with_config(
      uid,
      object_id,
      object_type,
      collab_db,
      collab_doc_state,
      persistence_config,
      build_config,
    )
  }

  /// Creates a new collaboration builder with the custom configuration.
  ///
  /// This function will initiate the creation of a [MutexCollab] object if it does not already exist.
  /// To check for the existence of the object prior to creation, you should utilize a transaction
  /// returned by the [read_txn] method of the [CollabKVDB]. Then, invoke the [is_exist] method
  /// to confirm the object's presence.
  ///
  /// # Parameters
  /// - `uid`: The user ID associated with the collaboration.
  /// - `object_id`: A string reference representing the ID of the object.
  /// - `object_type`: The type of the collaboration, defined by the [CollabType] enum.
  /// - `raw_data`: The raw data of the collaboration object, defined by the [CollabDocState] type.
  /// - `collab_db`: A weak reference to the [CollabKVDB].
  ///
  #[allow(clippy::too_many_arguments)]
  #[instrument(
    level = "trace",
    skip(self, collab_db, collab_doc_state, persistence_config, build_config)
  )]
  pub fn build_with_config(
    &self,
    uid: i64,
    object_id: &str,
    object_type: CollabType,
    collab_db: Weak<CollabKVDB>,
    collab_doc_state: DataSource,
    #[allow(unused_variables)] persistence_config: CollabPersistenceConfig,
    build_config: CollabBuilderConfig,
  ) -> Result<Arc<MutexCollab>, Error> {
    let collab = CollabBuilder::new(uid, object_id)
      .with_doc_state(collab_doc_state)
      .with_device_id(self.workspace_integrate.device_id())
      .build()?;

    #[cfg(target_arch = "wasm32")]
    {
      collab.lock().add_plugin(Box::new(IndexeddbDiskPlugin::new(
        uid,
        object_id.to_string(),
        object_type.clone(),
        collab_db.clone(),
      )));
    }

    #[cfg(not(target_arch = "wasm32"))]
    {
      collab
        .lock()
        .add_plugin(Box::new(RocksdbDiskPlugin::new_with_config(
          uid,
          object_id.to_string(),
          object_type.clone(),
          collab_db.clone(),
          persistence_config.clone(),
          None,
        )));
    }

    let arc_collab = Arc::new(collab);

    {
      let collab_object = self.collab_object(uid, object_id, object_type.clone())?;
      if build_config.sync_enable {
        let provider_type = self.plugin_provider.read().provider_type();
        let span = tracing::span!(tracing::Level::TRACE, "collab_builder", object_id = %object_id);
        let _enter = span.enter();
        match provider_type {
          CollabPluginProviderType::AppFlowyCloud => {
            let local_collab = Arc::downgrade(&arc_collab);
            let plugins =
              self
                .plugin_provider
                .read()
                .get_plugins(CollabPluginProviderContext::AppFlowyCloud {
                  uid,
                  collab_object,
                  local_collab,
                });

            for plugin in plugins {
              arc_collab.lock().add_plugin(plugin);
            }
          },
          CollabPluginProviderType::Supabase => {
            #[cfg(not(target_arch = "wasm32"))]
            {
              trace!("init supabase collab plugins");
              let local_collab = Arc::downgrade(&arc_collab);
              let local_collab_db = collab_db.clone();
              let plugins =
                self
                  .plugin_provider
                  .read()
                  .get_plugins(CollabPluginProviderContext::Supabase {
                    uid,
                    collab_object,
                    local_collab,
                    local_collab_db,
                  });
              for plugin in plugins {
                arc_collab.lock().add_plugin(plugin);
              }
            }
          },
          CollabPluginProviderType::Local => {},
        }
      }
    }

    if build_config.auto_initialize {
      #[cfg(target_arch = "wasm32")]
      futures::executor::block_on(arc_collab.lock().initialize());

      #[cfg(not(target_arch = "wasm32"))]
      arc_collab.lock().initialize();
    }

    trace!("collab initialized: {}:{}", object_type, object_id);
    Ok(arc_collab)
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
