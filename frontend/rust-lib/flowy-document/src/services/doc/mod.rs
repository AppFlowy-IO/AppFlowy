pub mod edit;
pub mod revision;
mod web_socket;
pub use crate::services::ws_handlers::*;
pub use edit::*;
pub use revision::*;

pub const SYNC_INTERVAL_IN_MILLIS: u64 = 1000;
