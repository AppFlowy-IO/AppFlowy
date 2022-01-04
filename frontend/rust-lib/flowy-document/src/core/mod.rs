pub mod edit;
pub mod revision;
mod web_socket;
pub use crate::ws_receivers::*;
pub use edit::*;
pub use revision::*;

pub const SYNC_INTERVAL_IN_MILLIS: u64 = 1000;
