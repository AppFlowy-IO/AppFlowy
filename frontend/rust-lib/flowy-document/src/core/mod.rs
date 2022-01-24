mod editor;
mod queue;
mod web_socket;

pub use editor::*;
pub(crate) use queue::*;
pub(crate) use web_socket::*;

pub const DOCUMENT_SYNC_INTERVAL_IN_MILLIS: u64 = 1000;
