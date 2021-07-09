mod database;
mod errors;
mod schema;

#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_derives;
#[macro_use]
extern crate diesel_migrations;

pub use flowy_infra::sqlite::DataBase;

pub use database::init;
pub use errors::*;
