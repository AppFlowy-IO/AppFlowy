pub use collab::core::collab::MutexCollab;
pub use collab::preclude::Snapshot;
pub use collab_plugins::local_storage::CollabPersistenceConfig;
pub use collab_plugins::CollabKVDB;
use collab_plugins::{if_native, if_wasm};

pub mod collab_builder;
pub mod config;

if_native! {
    mod native;
    mod plugin_provider {
        pub use crate::native::plugin_provider::*;
    }
}

if_wasm! {
    mod wasm;
    mod plugin_provider {
        pub use crate::wasm::plugin_provider::*;
    }
}

pub use collab_plugins::local_storage::kv::doc::CollabKVAction;
pub use collab_plugins::local_storage::kv::error::PersistenceError;
pub use collab_plugins::local_storage::kv::snapshot::{CollabSnapshot, SnapshotPersistence};
