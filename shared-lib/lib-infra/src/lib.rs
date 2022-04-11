pub mod code_gen;
pub mod future;
pub mod retry;

#[allow(dead_code)]
pub fn timestamp() -> i64 {
    chrono::Utc::now().timestamp()
}
