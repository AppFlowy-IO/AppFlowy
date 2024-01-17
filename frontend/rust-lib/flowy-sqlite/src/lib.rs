#[macro_use]
pub extern crate diesel;
#[macro_use]
pub extern crate diesel_derives;
#[macro_use]
extern crate diesel_migrations;

use std::{fmt::Debug, io, path::Path};

pub use diesel::*;
pub use diesel_derives::*;
use diesel_migrations::{EmbeddedMigrations, MigrationHarness};

use crate::sqlite_impl::PoolConfig;
pub use crate::sqlite_impl::{ConnectionPool, DBConnection, Database};

pub mod kv;
mod sqlite_impl;

pub mod schema;

#[macro_use]
pub mod macros;

pub type Error = diesel::result::Error;
pub mod prelude {
  pub use diesel::SqliteConnection;
  pub use diesel::{query_dsl::*, BelongingToDsl, ExpressionMethods, RunQueryDsl};

  pub use crate::*;
}

pub const MIGRATIONS: EmbeddedMigrations = embed_migrations!("../flowy-sqlite/migrations/");
pub const DB_NAME: &str = "flowy-database.db";

pub fn init<P: AsRef<Path>>(storage_path: P) -> Result<Database, io::Error> {
  let storage_path = storage_path.as_ref().to_str().unwrap();
  if !Path::new(storage_path).exists() {
    std::fs::create_dir_all(storage_path)?;
  }
  let pool_config = PoolConfig::default();
  let database = Database::new(storage_path, DB_NAME, pool_config).map_err(as_io_error)?;
  let mut conn = database.get_connection().map_err(as_io_error)?;
  (*conn)
    .run_pending_migrations(MIGRATIONS)
    .map_err(|e| io::Error::new(io::ErrorKind::Other, format!("{:?}", e)))?;
  Ok(database)
}

fn as_io_error<E>(e: E) -> io::Error
where
  E: Into<crate::sqlite_impl::Error> + Debug,
{
  let msg = format!("{:?}", e);
  io::Error::new(io::ErrorKind::NotConnected, msg)
}
