pub use collab::preclude::Snapshot;
pub use collab_plugins::CollabKVDB;
pub use collab_plugins::local_storage::CollabPersistenceConfig;

pub mod collab_builder;
pub mod config;
pub mod instant_indexed_data_provider;
mod plugin_provider;

pub use collab_plugins::local_storage::kv::doc::CollabKVAction;
pub use collab_plugins::local_storage::kv::error::PersistenceError;
pub use collab_plugins::local_storage::kv::snapshot::{CollabSnapshot, SnapshotPersistence};
