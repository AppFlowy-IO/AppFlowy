pub(crate) use app::controller::*;
pub(crate) use trash::controller::*;
pub(crate) use view::controller::*;
pub(crate) use workspace::controller::*;

pub(crate) mod app;
pub mod folder_editor;
pub(crate) mod persistence;
pub(crate) mod trash;
pub(crate) mod view;
mod web_socket;
pub(crate) mod workspace;

pub const FOLDER_SYNC_INTERVAL_IN_MILLIS: u64 = 1000;
