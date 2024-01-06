use std::fmt::{Debug, Display};
use std::sync::{Arc, Weak};

use anyhow::Error;
use collab::core::collab::{CollabDocState, MutexCollab};
use collab::preclude::{CollabBuilder, CollabPlugin};
use collab_entity::{CollabObject, CollabType};
use collab_plugins::connect_state::{CollabConnectReachability, CollabConnectState};
use collab_plugins::local_storage::kv::snapshot::SnapshotPersistence;
use collab_plugins::local_storage::rocksdb::rocksdb_plugin::{RocksdbBackup, RocksdbDiskPlugin};
use collab_plugins::local_storage::rocksdb::snapshot_plugin::CollabSnapshotPlugin;
use collab_plugins::local_storage::CollabPersistenceConfig;
use parking_lot::{Mutex, RwLock};
use tracing::trace;

use crate::CollabKVDB;
use lib_infra::future::Fut;

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

pub trait CollabCloudPluginProvider: Send + Sync + 'static {
  fn provider_type(&self) -> CollabPluginProviderType;

  fn get_plugins(&self, context: CollabPluginProviderContext) -> Fut<Vec<Arc<dyn CollabPlugin>>>;

  fn is_sync_enabled(&self) -> bool;
}

impl<T> CollabCloudPluginProvider for Arc<T>
where
  T: CollabCloudPluginProvider,
{
  fn provider_type(&self) -> CollabPluginProviderType {
    (**self).provider_type()
  }

  fn get_plugins(&self, context: CollabPluginProviderContext) -> Fut<Vec<Arc<dyn CollabPlugin>>> {
    (**self).get_plugins(context)
  }

  fn is_sync_enabled(&self) -> bool {
    (**self).is_sync_enabled()
  }
}

pub struct AppFlowyCollabBuilder {
  network_reachability: CollabConnectReachability,
  workspace_id: RwLock<Option<String>>,
  plugin_provider: tokio::sync::RwLock<Arc<dyn CollabCloudPluginProvider>>,
  snapshot_persistence: Mutex<Option<Arc<dyn SnapshotPersistence>>>,
  rocksdb_backup: Mutex<Option<Arc<dyn RocksdbBackup>>>,
  device_id: String,
}

pub struct CollabBuilderConfig {
  pub sync_enable: bool,
}

impl Default for CollabBuilderConfig {
  fn default() -> Self {
    Self { sync_enable: true }
  }
}

impl CollabBuilderConfig {
  pub fn sync_enable(mut self, sync_enable: bool) -> Self {
    self.sync_enable = sync_enable;
    self
  }
}

impl AppFlowyCollabBuilder {
  pub fn new<T: CollabCloudPluginProvider>(storage_provider: T, device_id: String) -> Self {
    Self {
      network_reachability: CollabConnectReachability::new(),
      workspace_id: Default::default(),
      plugin_provider: tokio::sync::RwLock::new(Arc::new(storage_provider)),
      snapshot_persistence: Default::default(),
      rocksdb_backup: Default::default(),
      device_id,
    }
  }

  pub fn set_snapshot_persistence(&self, snapshot_persistence: Arc<dyn SnapshotPersistence>) {
    *self.snapshot_persistence.lock() = Some(snapshot_persistence);
  }

  pub fn set_rocksdb_backup(&self, rocksdb_backup: Arc<dyn RocksdbBackup>) {
    *self.rocksdb_backup.lock() = Some(rocksdb_backup);
  }

  pub fn initialize(&self, workspace_id: String) {
    *self.workspace_id.write() = Some(workspace_id);
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
    let workspace_id = self.workspace_id.read().clone().ok_or_else(|| {
      anyhow::anyhow!("When using supabase plugin, the workspace_id should not be empty")
    })?;
    Ok(CollabObject::new(
      uid,
      object_id.to_string(),
      collab_type,
      workspace_id,
      self.device_id.clone(),
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
    collab_doc_state: CollabDocState,
    collab_db: Weak<CollabKVDB>,
    build_config: CollabBuilderConfig,
  ) -> Result<Arc<MutexCollab>, Error> {
    let persistence_config = CollabPersistenceConfig::default();
    self
      .build_with_config(
        uid,
        object_id,
        object_type,
        collab_db,
        collab_doc_state,
        &persistence_config,
        build_config,
      )
      .await
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
  pub async fn build_with_config(
    &self,
    uid: i64,
    object_id: &str,
    object_type: CollabType,
    collab_db: Weak<CollabKVDB>,
    collab_doc_state: CollabDocState,
    persistence_config: &CollabPersistenceConfig,
    build_config: CollabBuilderConfig,
  ) -> Result<Arc<MutexCollab>, Error> {
    let collab = Arc::new(
      CollabBuilder::new(uid, object_id)
        .with_doc_state(collab_doc_state)
        .with_plugin(RocksdbDiskPlugin::new_with_config(
          uid,
          collab_db.clone(),
          persistence_config.clone(),
          self.rocksdb_backup.lock().clone(),
        ))
        .with_device_id(self.device_id.clone())
        .build()?,
    );
    {
      let collab_object = self.collab_object(uid, object_id, object_type)?;
      if build_config.sync_enable {
        let provider_type = self.plugin_provider.read().await.provider_type();
        let span = tracing::span!(tracing::Level::TRACE, "collab_builder", object_id = %object_id);
        let _enter = span.enter();
        match provider_type {
          CollabPluginProviderType::AppFlowyCloud => {
            trace!("init appflowy cloud collab plugins");
            let local_collab = Arc::downgrade(&collab);
            let plugins = self
              .plugin_provider
              .read()
              .await
              .get_plugins(CollabPluginProviderContext::AppFlowyCloud {
                uid,
                collab_object: collab_object.clone(),
                local_collab,
              })
              .await;

            trace!("add appflowy cloud collab plugins: {}", plugins.len());
            for plugin in plugins {
              collab.lock().add_plugin(plugin);
            }
          },
          CollabPluginProviderType::Supabase => {
            trace!("init supabase collab plugins");
            let local_collab = Arc::downgrade(&collab);
            let local_collab_db = collab_db.clone();
            let plugins = self
              .plugin_provider
              .read()
              .await
              .get_plugins(CollabPluginProviderContext::Supabase {
                uid,
                collab_object: collab_object.clone(),
                local_collab,
                local_collab_db,
              })
              .await;
            for plugin in plugins {
              collab.lock().add_plugin(plugin);
            }
          },
          CollabPluginProviderType::Local => {},
        }
      }

      if let Some(snapshot_persistence) = self.snapshot_persistence.lock().as_ref() {
        if persistence_config.enable_snapshot {
          let snapshot_plugin = CollabSnapshotPlugin::new(
            uid,
            collab_object,
            snapshot_persistence.clone(),
            collab_db,
            persistence_config.snapshot_per_update,
          );
          // tracing::trace!("add snapshot plugin: {}", object_id);
          collab.lock().add_plugin(Arc::new(snapshot_plugin));
        }
      }
    }

    collab.lock().initialize();
    trace!("collab initialized: {}", object_id);
    Ok(collab)
  }
}
