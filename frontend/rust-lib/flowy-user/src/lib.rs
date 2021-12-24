pub mod entities;
pub mod event;
mod handlers;
pub mod module;
pub mod notify;
pub mod protobuf;
pub mod services;
mod sql_tables;

#[macro_use]
extern crate flowy_database;

pub mod prelude {
    pub use crate::{entities::*, services::server::*};
}

pub mod errors {
    pub use flowy_error::{internal_error, ErrorCode, FlowyError};
}
