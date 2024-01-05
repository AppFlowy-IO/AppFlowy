use diesel::{
  sql_query,
  sql_types::{BigInt, Text},
  QueryResult, RunQueryDsl, SqliteConnection,
};

/// The search content table stores the row content.
const SEARCH_CONTENT_TABLE: &str = "search_content";
const CREATE_SEARCH_CONTENT_TABLE: &str = r#"CREATE TABLE IF NOT EXISTS search_content (
    rowid INTEGER PRIMARY KEY,
    index_type TEXT,
    view_id TEXT,
    id TEXT,
    data TEXT,
    updated_at INTEGER DEFAULT (strftime('%s', 'now'))
)"#;

/// The search index table stores the full-text index.
const SEARCH_INDEX_TABLE: &str = "search_index";
const CREATE_SEARCH_INDEX_TABLE: &str = r#"CREATE VIRTUAL TABLE IF NOT EXISTS search_index USING fts5(
    data,
    content='search_content',
    content_rowid='rowid',
)"#;

const DROP_INDEX_INSERT_TRIGGER: &str = "DROP TRIGGER IF EXISTS search_index_insert";
const DROP_INDEX_DELETE_TRIGGER: &str = "DROP TRIGGER IF EXISTS search_index_delete";
const DROP_INDEX_UPDATE_TRIGGER: &str = "DROP TRIGGER IF EXISTS search_index_update";

const CREATE_INDEX_INSERT_TRIGGER: &str = r#"
CREATE TRIGGER search_index_insert AFTER INSERT ON search_content BEGIN
  INSERT INTO search_index(rowid, data) VALUES (new.rowid, new.data);
END;
"#;

const CREATE_INDEX_DELETE_TRIGGER: &str = r#"
CREATE TRIGGER search_index_delete AFTER DELETE ON search_content BEGIN
  INSERT INTO search_index(search_index, rowid, data) VALUES ('delete', old.rowid, old.data);
END;
"#;

const CREATE_INDEX_UPDATE_TRIGGER: &str = r#"
CREATE TRIGGER search_index_update AFTER UPDATE ON search_content BEGIN
  INSERT INTO search_index(search_index, rowid, data) VALUES ('delete', old.rowid, old.data);
  INSERT INTO search_index(rowid, data) VALUES (new.rowid, new.data);
END;
"#;

/// Runs database migrations for local search using sqlite FTS5.
///
/// FTS5 tables do not have indexes, which is not supported by Diesel.
pub fn run_migrations(conn: &mut SqliteConnection) -> QueryResult<usize> {
  if !table_exists(conn, SEARCH_CONTENT_TABLE)? {
    sql_query(CREATE_SEARCH_CONTENT_TABLE).execute(conn)?;
  }
  if !table_exists(conn, SEARCH_INDEX_TABLE)? {
    sql_query(CREATE_SEARCH_INDEX_TABLE).execute(conn)?;
  }

  // drop and create triggers because no create if not exists for triggers.
  sql_query(DROP_INDEX_INSERT_TRIGGER).execute(conn)?;
  sql_query(DROP_INDEX_DELETE_TRIGGER).execute(conn)?;
  sql_query(DROP_INDEX_UPDATE_TRIGGER).execute(conn)?;
  sql_query(CREATE_INDEX_INSERT_TRIGGER).execute(conn)?;
  sql_query(CREATE_INDEX_DELETE_TRIGGER).execute(conn)?;
  sql_query(CREATE_INDEX_UPDATE_TRIGGER).execute(conn)?;

  Ok(0)
}

#[derive(Debug, QueryableByName)]
struct ShowTablesRow {
  #[allow(dead_code)]
  #[diesel(sql_type=Text)]
  name: String,
}

fn table_exists(conn: &mut SqliteConnection, table: &str) -> QueryResult<bool> {
  let tables: Vec<ShowTablesRow> =
    sql_query("SELECT name FROM sqlite_master WHERE type='table' AND name=?")
      .bind::<Text, _>(table)
      .load(conn)?;
  Ok(!tables.is_empty())
}

/// The type of data that is stored in the search index row.
#[derive(Debug)]
pub enum IndexType {
  /// Name of the view is stored in data.
  View,
  /// Text of the document is stored in data.
  Document,
}

impl ToString for IndexType {
  fn to_string(&self) -> String {
    match self {
      IndexType::View => "view".to_owned(),
      IndexType::Document => "document".to_owned(),
    }
  }
}

/// SearchData represents the data that is contained by a view and the type of document.
#[derive(Debug, QueryableByName)]
pub struct SearchData {
  /// The type of data that is stored in the search index row.
  #[diesel(sql_type = Text)]
  pub index_type: String,

  /// The `View` that the row references.
  #[diesel(sql_type = Text)]
  pub view_id: String,

  /// The ID that corresponds to the type that is stored.
  /// View: view_id
  /// Document: page_id
  #[diesel(sql_type = Text)]
  pub id: String,

  /// The data that is stored in the search index row.
  #[diesel(sql_type = Text)]
  pub data: String,

  #[diesel(sql_type = BigInt)]
  pub updated_at: i64,
}

impl PartialEq for SearchData {
  fn eq(&self, other: &Self) -> bool {
    self.index_type == other.index_type
      && self.view_id == other.view_id
      && self.id == other.id
      && self.data == other.data
  }
}

impl SearchData {
  pub fn new_view(view_id: &str, name: &str) -> Self {
    Self {
      index_type: IndexType::View.to_string(),
      view_id: view_id.to_owned(),
      id: view_id.to_owned(),
      data: name.to_owned(),
      updated_at: 0,
    }
  }

  pub fn new_document(view_id: &str, page_id: &str, text: &str) -> Self {
    Self {
      index_type: IndexType::Document.to_string(),
      view_id: view_id.to_owned(),
      id: page_id.to_owned(),
      data: text.to_owned(),
      updated_at: 0,
    }
  }
}

/// Add search data for searching.
pub fn add(conn: &mut SqliteConnection, data: &SearchData) -> QueryResult<usize> {
  sql_query("INSERT INTO search_content (index_type, view_id, id, data) VALUES (?,?,?,?)")
    .bind::<Text, _>(&data.index_type)
    .bind::<Text, _>(&data.view_id)
    .bind::<Text, _>(&data.id)
    .bind::<Text, _>(&data.data)
    .execute(conn)
}

/// Update view name.
pub fn update_view(conn: &mut SqliteConnection, data: &SearchData) -> QueryResult<usize> {
  sql_query("UPDATE search_content SET data=? WHERE index_type=? and view_id=?")
    .bind::<Text, _>(&data.data)
    .bind::<Text, _>(IndexType::View.to_string())
    .bind::<Text, _>(&data.view_id)
    .execute(conn)
}

/// Search index for matches.
pub fn search_index(conn: &mut SqliteConnection, s: &str) -> QueryResult<Vec<SearchData>> {
  let query = r#"SELECT
      search_content.index_type, search_content.view_id, search_content.id, search_content.data, search_content.updated_at
      FROM search_index
      INNER JOIN search_content ON search_content.rowid = search_index.rowid
      WHERE search_index.data MATCH ?"#;
  sql_query(query).bind::<Text, _>(s).load(conn)
}

/// Delete view and data associated with the view.
///
/// - Document: delete the row that contains the text.
pub fn delete_view(conn: &mut SqliteConnection, id: &str) -> QueryResult<usize> {
  sql_query("DELETE FROM search_content WHERE view_id=?")
    .bind::<Text, _>(id)
    .execute(conn)
}

/// Update document text.
pub fn update_document(conn: &mut SqliteConnection, data: &SearchData) -> QueryResult<usize> {
  sql_query("UPDATE search_content SET data=? WHERE index_type=? and id=?")
    .bind::<Text, _>(&data.data)
    .bind::<Text, _>(IndexType::Document.to_string())
    .bind::<Text, _>(&data.id)
    .execute(conn)
}

/// Delete document data using page_id.
pub fn delete_document(conn: &mut SqliteConnection, id: &str) -> QueryResult<usize> {
  sql_query("DELETE FROM search_content WHERE index_type=? and id=?")
    .bind::<Text, _>(IndexType::Document.to_string())
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
  fn test_view_search() -> QueryResult<()> {
    let (_tempdir, database) = setup_db();
    let mut conn = database.get_connection().unwrap();
    assert!(table_exists(&mut conn, SEARCH_INDEX_TABLE).unwrap());

    // add views we will try to match
    let first = SearchData::new_view("asdf", "First doc");
    let second = SearchData::new_view("qwer", "Second doc");
    add(&mut conn, &first).unwrap();
    add(&mut conn, &second).unwrap();

    // add views that should not match
    let unrelated = SearchData::new_view("zxcv", "unrelated");
    add(&mut conn, &unrelated).unwrap();

    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.contains(&first));
    assert!(results.contains(&second));

    // remove views
    delete_view(&mut conn, &first.view_id).unwrap();
    delete_view(&mut conn, &second.view_id).unwrap();
    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.is_empty());

    Ok(())
  }

  #[test]
  fn test_view_update() -> QueryResult<()> {
    let (_tempdir, database) = setup_db();
    let mut conn = database.get_connection().unwrap();
    assert!(table_exists(&mut conn, SEARCH_INDEX_TABLE).unwrap());

    // add views we will try to match
    let view = SearchData::new_view("asdf", "First doc");
    add(&mut conn, &view).unwrap();

    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.contains(&view));

    // update view title
    let view = SearchData {
      data: "new title".to_owned(),
      ..view
    };
    update_view(&mut conn, &view).unwrap();
    // prev search
    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.is_empty());

    // updated search
    let results = search_index(&mut conn, "new").unwrap();
    assert!(results.contains(&view));

    Ok(())
  }

  #[test]
  fn test_doc_search() -> QueryResult<()> {
    let (_tempdir, database) = setup_db();
    let mut conn = database.get_connection().unwrap();
    assert!(table_exists(&mut conn, SEARCH_INDEX_TABLE).unwrap());

    // add docs we will try to match
    let first = SearchData::new_document("asdf", "123", "First doc");
    let second = SearchData::new_document("qwer", "456", "Second doc");
    add(&mut conn, &first).unwrap();
    add(&mut conn, &second).unwrap();

    // add docs that should not match
    let unrelated = SearchData::new_document("zxcv", "987", "unrelated");
    add(&mut conn, &unrelated).unwrap();

    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.contains(&first));
    assert!(results.contains(&second));

    // remove doc using page_id
    delete_document(&mut conn, &first.id).unwrap();
    // remove doc using view_id
    delete_view(&mut conn, &second.view_id).unwrap();
    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.is_empty());

    Ok(())
  }

  #[test]
  fn test_doc_update() -> QueryResult<()> {
    let (_tempdir, database) = setup_db();
    let mut conn = database.get_connection().unwrap();
    assert!(table_exists(&mut conn, SEARCH_INDEX_TABLE).unwrap());

    // add docs we will try to match
    let doc = SearchData::new_document("asdf", "123", "First doc");
    add(&mut conn, &doc).unwrap();

    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.contains(&doc));

    // update doc content
    let doc = SearchData {
      data: "new content".to_owned(),
      ..doc
    };
    update_document(&mut conn, &doc).unwrap();
    // prev search
    let results = search_index(&mut conn, "doc").unwrap();
    assert!(results.is_empty());

    // updated search
    let results = search_index(&mut conn, "new").unwrap();
    assert!(results.contains(&doc));

    Ok(())
  }
}
