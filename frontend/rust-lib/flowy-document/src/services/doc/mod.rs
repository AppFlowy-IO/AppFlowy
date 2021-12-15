pub mod edit;
pub mod revision;

pub(crate) mod controller;

mod ws_manager;
pub use ws_manager::*;

pub const SYNC_INTERVAL_IN_MILLIS: u64 = 500;
