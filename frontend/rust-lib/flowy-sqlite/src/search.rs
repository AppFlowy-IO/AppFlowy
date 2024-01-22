use diesel::sql_types::Text;

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
