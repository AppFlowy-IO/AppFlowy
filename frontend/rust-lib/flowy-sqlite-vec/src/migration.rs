use include_dir::{include_dir, Dir};
use rusqlite::Connection;
use rusqlite_migration::Migrations;
use std::path::Path;
use std::sync::LazyLock;

static MIGRATIONS_DIR: Dir = include_dir!("$CARGO_MANIFEST_DIR/migrations");
static MIGRATIONS: LazyLock<Migrations<'static>> =
  LazyLock::new(|| Migrations::from_directory(&MIGRATIONS_DIR).unwrap());

/// Initialize a new SQLite database with migrations
pub fn init_sqlite_with_migrations(db_path: &Path) -> anyhow::Result<Connection> {
  let mut conn = Connection::open(db_path)?;
  MIGRATIONS.to_latest(&mut conn)?;
  Ok(conn)
}
