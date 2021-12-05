#[macro_use]
extern crate diesel;

#[macro_use]
extern crate diesel_derives;

pub mod entities;
pub mod future;
pub mod kv;
mod protobuf;
pub mod retry;

#[allow(dead_code)]
pub fn uuid() -> String { uuid::Uuid::new_v4().to_string() }

#[allow(dead_code)]
pub fn timestamp() -> i64 { chrono::Utc::now().timestamp() }
