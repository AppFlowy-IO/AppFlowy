pub use collab::core::collab::MutexCollab;
pub use collab::preclude::Snapshot;
pub use collab_persistence::doc::YrsDocAction;
pub use collab_persistence::error::PersistenceError;
#[cfg(any(
  feature = "aws_storage_plugin",
  feature = "postgres_storage_plugin",
  feature = "rocksdb_plugin"
))]
pub use collab_persistence::kv::rocks_kv::RocksCollabDB;
pub use collab_persistence::snapshot::CollabSnapshot;

#[cfg(feature = "postgres_storage_plugin")]
pub use collab_plugins::cloud_storage::*;

#[cfg(any(
  feature = "aws_storage_plugin",
  feature = "postgres_storage_plugin",
  feature = "rocksdb_plugin"
))]
pub use collab_plugins::local_storage::CollabPersistenceConfig;

#[cfg(feature = "snapshot_plugin")]
pub use collab_plugins::snapshot::{
  calculate_snapshot_diff, try_encode_snapshot, SnapshotPersistence,
};

pub mod collab_builder;
pub mod config;
