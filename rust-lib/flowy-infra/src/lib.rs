#[macro_use]
extern crate diesel;

#[macro_use]
extern crate diesel_derives;

pub mod future;
pub mod kv;
mod protobuf;

#[allow(dead_code)]
pub fn uuid() -> String { uuid::Uuid::new_v4().to_string() }

#[allow(dead_code)]
pub fn timestamp() -> i64 { chrono::Utc::now().timestamp() }
