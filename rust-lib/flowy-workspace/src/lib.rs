pub use flowy_workspace_infra::entities;

pub mod event;
pub mod module;
mod services;

#[macro_use]
mod macros;

#[macro_use]
extern crate flowy_database;

pub mod errors;
pub mod handlers;
mod notify;
pub mod protobuf;
mod sql_tables;

pub mod prelude {
    pub use flowy_workspace_infra::entities::{app::*, trash::*, view::*, workspace::*};

    pub use crate::{errors::*, module::*, services::*};
}
