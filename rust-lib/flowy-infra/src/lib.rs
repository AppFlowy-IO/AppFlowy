#[macro_use]
extern crate diesel;

#[macro_use]
extern crate diesel_derives;

pub mod kv;
mod protobuf;

pub fn uuid() -> String { uuid::Uuid::new_v4().to_string() }
pub fn timestamp() -> i64 { chrono::Utc::now().timestamp() }
