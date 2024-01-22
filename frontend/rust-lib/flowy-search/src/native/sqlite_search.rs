use diesel::{
  sql_query,
  sql_types::{BigInt, Text},
  QueryResult, RunQueryDsl, SqliteConnection,
};
use diesel_derives::QueryableByName;
use tracing::{info, instrument};

#[derive(Debug, QueryableByName)]
struct ShowTablesRow {
  #[allow(dead_code)]
  #[diesel(sql_type=Text)]
  name: String,
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
#[derive(Debug, PartialEq, QueryableByName)]
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
}

impl SearchData {
  pub fn new_view(view_id: &str, content: &str) -> Self {
    Self {
      index_type: IndexType::View.to_string(),
      view_id: view_id.to_owned(),
      id: view_id.to_owned(),
      data: content.to_owned(),
    }
  }

  pub fn new_document(view_id: &str, page_id: &str, text: &str) -> Self {
    Self {
      index_type: IndexType::Document.to_string(),
      view_id: view_id.to_owned(),
      id: page_id.to_owned(),
      data: text.to_owned(),
    }
  }
}

/// Add search data for searching.
#[instrument(level = "debug", skip_all, err)]
pub fn create_index(conn: &mut SqliteConnection, data: &SearchData) -> QueryResult<usize> {
  info!("create index: {:?}", data);
  sql_query("INSERT INTO search_index (index_type, view_id, id, data) VALUES (?,?,?,?)")
    .bind::<Text, _>(&data.index_type)
    .bind::<Text, _>(&data.view_id)
    .bind::<Text, _>(&data.id)
    .bind::<Text, _>(&data.data)
    .execute(conn)
}

/// Update view name.
#[instrument(level = "debug", skip_all, err)]
pub fn update_index(conn: &mut SqliteConnection, data: &SearchData) -> QueryResult<usize> {
  info!("update index: {:?}", data);
  sql_query("UPDATE search_index SET data=? WHERE index_type=? and view_id=?")
    .bind::<Text, _>(&data.data)
    .bind::<Text, _>(IndexType::View.to_string())
    .bind::<Text, _>(&data.view_id)
    .execute(conn)
}

/// Search index for matches.
#[instrument(level = "debug", skip_all, err)]
pub fn search_index(
  conn: &mut SqliteConnection,
  s: &str,
  limit: Option<i64>,
) -> QueryResult<Vec<SearchData>> {
  let query = "SELECT index_type, view_id, id, data FROM search_index WHERE search_index MATCH ?";
  match limit {
    Some(limit) => {
      let query = format!("{} LIMIT ?", query);
      sql_query(query)
        .bind::<Text, _>(s)
        .bind::<BigInt, _>(limit)
        .load(conn)
    },
    None => sql_query(query).bind::<Text, _>(s).load(conn),
  }
}

/// Delete view and data associated with the view.
///
/// - Document: delete the row that contains the text.
pub fn delete_view(conn: &mut SqliteConnection, id: &str) -> QueryResult<usize> {
  sql_query("DELETE FROM search_index WHERE view_id=?")
    .bind::<Text, _>(id)
    .execute(conn)
}

/// Update document text.
pub fn update_document(conn: &mut SqliteConnection, data: &SearchData) -> QueryResult<usize> {
  sql_query("UPDATE search_index SET data=? WHERE index_type=? and id=?")
    .bind::<Text, _>(&data.data)
    .bind::<Text, _>(IndexType::Document.to_string())
    .bind::<Text, _>(&data.id)
    .execute(conn)
}

/// Delete document data using page_id.
pub fn delete_document(conn: &mut SqliteConnection, id: &str) -> QueryResult<usize> {
  sql_query("DELETE FROM search_index WHERE index_type=? and id=?")
    .bind::<Text, _>(IndexType::Document.to_string())
    .bind::<Text, _>(id)
    .execute(conn)
}

#[cfg(test)]
mod tests {}
