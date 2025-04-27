use rusqlite::ffi::sqlite3_auto_extension;
use sqlite_vec::sqlite3_vec_init;

pub mod db;
mod migration;

#[allow(clippy::missing_transmute_annotations)]
pub fn init_sqlite_vector_extension() {
  unsafe {
    sqlite3_auto_extension(Some(std::mem::transmute(sqlite3_vec_init as *const ())));
  }
}
