pub use collab::preclude::Snapshot;
pub use collab_plugins::local_storage::CollabPersistenceConfig;
pub use collab_plugins::CollabKVDB;

pub mod collab_builder;
pub mod config;
pub mod period_write;
mod plugin_provider;

pub use collab_plugins::local_storage::kv::doc::CollabKVAction;
pub use collab_plugins::local_storage::kv::error::PersistenceError;
pub use collab_plugins::local_storage::kv::snapshot::{CollabSnapshot, SnapshotPersistence};
