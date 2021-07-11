#[macro_use]
extern crate diesel;

#[macro_use]
extern crate diesel_derives;

#[macro_use]
extern crate diesel_migrations;

pub mod kv;
mod protobuf;

pub fn uuid() -> String { uuid::Uuid::new_v4().to_string() }
