mod auth;

pub use auth::*;

pub fn uuid() -> String { uuid::Uuid::new_v4().to_string() }
