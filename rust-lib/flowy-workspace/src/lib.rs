mod handlers;
mod notify;
mod services;
mod sql_tables;

pub mod entities;
pub mod errors;
pub mod event;
pub mod module;
pub mod protobuf;

#[macro_use]
mod macros;

#[macro_use]
extern crate flowy_database;

// #[macro_use]
// extern crate flowy_dispatch;

pub mod prelude {
    pub use crate::{
        entities::{app::*, view::*, workspace::*},
        errors::*,
        module::*,
        services::*,
    };
}
