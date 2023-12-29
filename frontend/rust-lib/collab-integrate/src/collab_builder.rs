use std::fmt::Debug;
use std::sync::{Arc, Weak};

use anyhow::Error;
use collab::core::collab::{CollabDocState, MutexCollab};
use collab::preclude::{CollabBuilder, CollabPlugin};
use collab_entity::{CollabObject, CollabType};
use collab_persistence::kv::rocks_kv::RocksCollabDB;
use collab_plugins::cloud_storage::network_state::{CollabNetworkReachability, CollabNetworkState};
use collab_plugins::local_storage::rocksdb::{RocksdbBackup, RocksdbDiskPlugin};
use collab_plugins::local_storage::CollabPersistenceConfig;
use collab_plugins::snapshot::{CollabSnapshotPlugin, SnapshotPersistence};
use parking_lot::{Mutex, RwLock};
use tracing::trace;

use lib_infra::future::Fut;

#[derive(Clone, Debug)]
pub enum CollabDataSource {
  Local,
  AppFlowyCloud,
  Supabase,
}

pub enum CollabStorageProviderContext {
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
    local_collab_db: Weak<RocksCollabDB>,
  },
}

pub trait CollabStorageProvider: Send + Sync + 'static {
  fn storage_source(&self) -> CollabDataSource;

  fn get_plugins(&self, context: CollabStorageProviderContext) -> Fut<Vec<Arc<dyn CollabPlugin>>>;

  fn is_sync_enabled(&self) -> bool;
}

impl<T> CollabStorageProvider for Arc<T>
where
  T: CollabStorageProvider,
{
  fn storage_source(&self) -> CollabDataSource {
    (**self).storage_source()
  }

  fn get_plugins(&self, context: CollabStorageProviderContext) -> Fut<Vec<Arc<dyn CollabPlugin>>> {
    (**self).get_plugins(context)
  }

  fn is_sync_enabled(&self) -> bool {
    (**self).is_sync_enabled()
  }
}

pub struct AppFlowyCollabBuilder {
  network_reachability: CollabNetworkReachability,
  workspace_id: RwLock<Option<String>>,
  cloud_storage: tokio::sync::RwLock<Arc<dyn CollabStorageProvider>>,
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
  pub fn new<T: CollabStorageProvider>(storage_provider: T, device_id: String) -> Self {
    Self {
      network_reachability: CollabNetworkReachability::new(),
      workspace_id: Default::default(),
      cloud_storage: tokio::sync::RwLock::new(Arc::new(storage_provider)),
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
        .set_state(CollabNetworkState::Connected)
    } else {
      self
        .network_reachability
        .set_state(CollabNetworkState::Disconnected)
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
  /// returned by the [read_txn] method of the [RocksCollabDB]. Then, invoke the [is_exist] method
  /// to confirm the object's presence.
  ///
  /// # Parameters
  /// - `uid`: The user ID associated with the collaboration.
  /// - `object_id`: A string reference representing the ID of the object.
  /// - `object_type`: The type of the collaboration, defined by the [CollabType] enum.
  /// - `raw_data`: The raw data of the collaboration object, defined by the [CollabDocState] type.
  /// - `collab_db`: A weak reference to the [RocksCollabDB].
  ///
  pub async fn build(
    &self,
    uid: i64,
    object_id: &str,
    object_type: CollabType,
    collab_doc_state: CollabDocState,
    collab_db: Weak<RocksCollabDB>,
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
  /// returned by the [read_txn] method of the [RocksCollabDB]. Then, invoke the [is_exist] method
  /// to confirm the object's presence.
  ///
  /// # Parameters
  /// - `uid`: The user ID associated with the collaboration.
  /// - `object_id`: A string reference representing the ID of the object.
  /// - `object_type`: The type of the collaboration, defined by the [CollabType] enum.
  /// - `raw_data`: The raw data of the collaboration object, defined by the [CollabDocState] type.
  /// - `collab_db`: A weak reference to the [RocksCollabDB].
  ///
  #[allow(clippy::too_many_arguments)]
  pub async fn build_with_config(
    &self,
    uid: i64,
    object_id: &str,
    object_type: CollabType,
    collab_db: Weak<RocksCollabDB>,
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
        let cloud_storage_type = self.cloud_storage.read().await.storage_source();
        let span = tracing::span!(tracing::Level::TRACE, "collab_builder", object_id = %object_id);
        let _enter = span.enter();
        match cloud_storage_type {
          CollabDataSource::AppFlowyCloud => {
            #[cfg(feature = "appflowy_cloud_integrate")]
            {
              trace!("init appflowy cloud collab plugins");
              let local_collab = Arc::downgrade(&collab);
              let plugins = self
                .cloud_storage
                .read()
                .await
                .get_plugins(CollabStorageProviderContext::AppFlowyCloud {
                  uid,
                  collab_object: collab_object.clone(),
                  local_collab,
                })
                .await;

              trace!("add appflowy cloud collab plugins: {}", plugins.len());
              for plugin in plugins {
                collab.lock().add_plugin(plugin);
              }
            }
          },
          CollabDataSource::Supabase => {
            #[cfg(feature = "supabase_integrate")]
            {
              trace!("init supabase collab plugins");
              let local_collab = Arc::downgrade(&collab);
              let local_collab_db = collab_db.clone();
              let plugins = self
                .cloud_storage
                .read()
                .await
                .get_plugins(CollabStorageProviderContext::Supabase {
                  uid,
                  collab_object: collab_object.clone(),
                  local_collab,
                  local_collab_db,
                })
                .await;
              for plugin in plugins {
                collab.lock().add_plugin(plugin);
              }
            }
          },
          CollabDataSource::Local => {},
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
