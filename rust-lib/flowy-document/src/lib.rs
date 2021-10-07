#![feature(vecdeque_binary_search)]

pub mod entities;
pub mod errors;
pub mod module;
mod notify;
pub mod protobuf;
pub mod services;
mod sql_tables;

#[macro_use]
extern crate flowy_database;

pub mod prelude {
    pub use crate::{
        module::*,
        services::{server::*, ws::*},
    };
}
