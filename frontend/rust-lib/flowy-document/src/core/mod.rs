pub mod edit;
pub mod revision;
mod web_socket;
<<<<<<< HEAD:frontend/rust-lib/flowy-document/src/services/doc/mod.rs
pub use crate::services::ws_receivers::*;
=======
pub use crate::ws_receivers::*;
>>>>>>> upstream/main:frontend/rust-lib/flowy-document/src/core/mod.rs
pub use edit::*;
pub use revision::*;

pub const SYNC_INTERVAL_IN_MILLIS: u64 = 1000;
