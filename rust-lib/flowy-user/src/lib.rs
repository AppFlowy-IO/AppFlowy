mod handlers;
mod sql_tables;

pub mod entities;
pub mod errors;
pub mod event;
pub mod module;
pub mod protobuf;
pub mod services;

#[macro_use]
extern crate flowy_database;

pub mod prelude {
    pub use crate::{
        entities::*,
        services::{user::*, workspace::*},
    };
}
