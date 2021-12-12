pub mod future;
pub mod retry;

#[allow(dead_code)]
pub fn uuid() -> String { uuid::Uuid::new_v4().to_string() }

#[allow(dead_code)]
pub fn timestamp() -> i64 { chrono::Utc::now().timestamp() }
