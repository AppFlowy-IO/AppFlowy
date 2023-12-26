use diesel::{sql_query, sql_types::Text, QueryResult, RunQueryDsl, SqliteConnection};

const SEARCH_VIEW_TABLE: &str = "search_view";
const CREATE_SEARCH_VIEW_TABLE: &str =
  "CREATE VIRTUAL TABLE if not exists search_view USING fts5(id, name)";

/// Runs database migrations for local search using sqlite FTS5.
///
/// FTS5 tables do not have indexes, which is not supported by Diesel.
pub fn run_migrations(conn: &mut SqliteConnection) -> QueryResult<usize> {
  if !table_exists(conn, SEARCH_VIEW_TABLE)? {
    sql_query(CREATE_SEARCH_VIEW_TABLE).execute(conn)?;
  }
  Ok(0)
}

#[derive(Debug, QueryableByName)]
struct ShowTablesRow {
  #[diesel(sql_type=Text)]
  name: String,
}

fn table_exists(conn: &mut SqliteConnection, table: &str) -> QueryResult<bool> {
  let tables: Vec<ShowTablesRow> =
    sql_query("SELECT name FROM sqlite_master WHERE type='table' AND name=?")
      .bind::<Text, _>(table)
      .load(conn)?;
  Ok(tables.len() > 0)
}

#[derive(Debug, PartialEq, QueryableByName)]
pub struct View {
  #[diesel(sql_type = Text)]
  pub id: String,
  #[diesel(sql_type = Text)]
  pub name: String,
}

pub fn add_view(conn: &mut SqliteConnection, view: &View) -> QueryResult<usize> {
  sql_query("INSERT INTO search_view (id, name) VALUES (?,?)")
    .bind::<Text, _>(&view.id)
    .bind::<Text, _>(&view.name)
    .execute(conn)
}

pub fn update_view(conn: &mut SqliteConnection, view: &View) -> QueryResult<usize> {
  sql_query("UPDATE search_view SET name=? WHERE id=?")
    .bind::<Text, _>(&view.name)
    .bind::<Text, _>(&view.id)
    .execute(conn)
}

pub fn search_view(conn: &mut SqliteConnection, s: &str) -> QueryResult<Vec<View>> {
  sql_query("SELECT id, name FROM search_view WHERE search_view MATCH ?")
    .bind::<Text, _>(s)
    .load(conn)
}

pub fn delete_view(conn: &mut SqliteConnection, id: &str) -> QueryResult<usize> {
  sql_query("DELETE FROM search_view WHERE id=?")
    .bind::<Text, _>(id)
    .execute(conn)
}

#[cfg(test)]
mod tests {

  use diesel_migrations::MigrationHarness;
  use tempfile::TempDir;

  use crate::{prelude::PoolConfig, Database, DB_NAME, MIGRATIONS};

  use super::*;

  fn setup_db() -> (TempDir, Database) {
    let tempdir = TempDir::new().unwrap();
    let path = tempdir.path().to_str().unwrap();
    let pool_config = PoolConfig::default();
    let database = Database::new(path, DB_NAME, pool_config).unwrap();
    let mut conn = database.get_connection().unwrap();
    (*conn).run_pending_migrations(MIGRATIONS).unwrap();
    run_migrations(&mut conn).unwrap();

    (tempdir, database)
  }

  #[test]
  fn test_migration() {
    let tempdir = TempDir::new().unwrap();
    let path = tempdir.path().to_str().unwrap();
    let pool_config = PoolConfig::default();
    let database = Database::new(path, DB_NAME, pool_config).unwrap();
    let mut conn = database.get_connection().unwrap();
    (*conn).run_pending_migrations(MIGRATIONS).unwrap();

    assert!(run_migrations(&mut conn).is_ok());
    assert!(run_migrations(&mut conn).is_ok()); // test idempotent
    assert!(table_exists(&mut conn, SEARCH_VIEW_TABLE).unwrap());
  }

  #[test]
  fn test_view_search() -> QueryResult<()> {
    let (_tempdir, database) = setup_db();
    let mut conn = database.get_connection().unwrap();
    assert!(table_exists(&mut conn, SEARCH_VIEW_TABLE).unwrap());

    // add views we will try to match
    let first = View {
      id: "asdf".to_owned(),
      name: "First doc".to_owned(),
    };
    let second = View {
      id: "qwer".to_owned(),
      name: "Second doc".to_owned(),
    };
    add_view(&mut conn, &first).unwrap();
    add_view(&mut conn, &second).unwrap();

    // add views that should not match
    let unrelated = View {
      id: "zxcv".to_owned(),
      name: "unrelated".to_owned(),
    };
    add_view(&mut conn, &unrelated).unwrap();

    let results = search_view(&mut conn, "doc").unwrap();
    assert!(results.contains(&first));
    assert!(results.contains(&second));

    // remove views
    delete_view(&mut conn, &first.id).unwrap();
    delete_view(&mut conn, &second.id).unwrap();
    let results = search_view(&mut conn, "doc").unwrap();
    assert!(results.is_empty());

    Ok(())
  }

  #[test]
  fn test_view_update() -> QueryResult<()> {
    let (_tempdir, database) = setup_db();
    let mut conn = database.get_connection().unwrap();
    assert!(table_exists(&mut conn, SEARCH_VIEW_TABLE).unwrap());

    // add views we will try to match
    let view = View {
      id: "asdf".to_owned(),
      name: "First doc".to_owned(),
    };
    add_view(&mut conn, &view).unwrap();

    let results = search_view(&mut conn, "doc").unwrap();
    assert!(results.contains(&view));

    // update view title
    let view = View {
      name: "new title".to_owned(),
      ..view
    };
    update_view(&mut conn, &view).unwrap();
    // prev search
    let results = search_view(&mut conn, "doc").unwrap();
    assert!(results.is_empty());

    // updated search
    let results = search_view(&mut conn, "new").unwrap();
    assert!(results.contains(&view));

    Ok(())
  }
}
