use include_dir::{include_dir, Dir};
use r2d2::PooledConnection;
use r2d2_sqlite::SqliteConnectionManager;
use rusqlite_migration::Migrations;
use std::sync::LazyLock;

static MIGRATIONS_DIR: Dir = include_dir!("$CARGO_MANIFEST_DIR/migrations");
static MIGRATIONS: LazyLock<Migrations<'static>> =
  LazyLock::new(|| Migrations::from_directory(&MIGRATIONS_DIR).unwrap());

/// Initialize a new SQLite database with migrations
pub fn init_sqlite_with_migrations(
  conn: &mut PooledConnection<SqliteConnectionManager>,
) -> anyhow::Result<()> {
  MIGRATIONS.to_latest(conn)?;
  Ok(())
}
