pub mod future;
pub mod retry;

#[cfg(feature = "pb_gen")]
pub mod pb_gen;

#[allow(dead_code)]
pub fn uuid_string() -> String {
    uuid::Uuid::new_v4().to_string()
}

#[allow(dead_code)]
pub fn timestamp() -> i64 {
    chrono::Utc::now().timestamp()
}
