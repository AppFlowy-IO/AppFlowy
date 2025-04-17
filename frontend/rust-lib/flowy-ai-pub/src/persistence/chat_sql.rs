use diesel::sqlite::SqliteConnection;
use flowy_error::FlowyResult;
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{chat_table, chat_table::dsl},
  AsChangeset, DBConnection, ExpressionMethods, Identifiable, Insertable, QueryResult, Queryable,
};
use serde::{Deserialize, Serialize};

#[derive(Clone, Default, Queryable, Insertable, Identifiable)]
#[diesel(table_name = chat_table)]
#[diesel(primary_key(chat_id))]
pub struct ChatTable {
  pub chat_id: String,
  pub created_at: i64,
  pub name: String,
  pub metadata: String,
  pub rag_ids: Option<String>,
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ChatTableMetadata {
  pub files: Vec<ChatTableFile>,
}

impl ChatTableMetadata {
  pub fn add_file(&mut self, name: String, id: String) {
    if let Some(file) = self.files.iter_mut().find(|f| f.name == name) {
      file.id = id;
    } else {
      self.files.push(ChatTableFile { name, id });
    }
  }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ChatTableFile {
  pub name: String,
  pub id: String,
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = chat_table)]
#[diesel(primary_key(chat_id))]
pub struct ChatTableChangeset {
  pub chat_id: String,
  pub name: Option<String>,
  pub metadata: Option<String>,
  pub rag_ids: Option<String>,
}

impl ChatTableChangeset {
  pub fn from_metadata(metadata: ChatTableMetadata) -> Self {
    ChatTableChangeset {
      chat_id: Default::default(),
      metadata: serde_json::to_string(&metadata).ok(),
      name: None,
      rag_ids: None,
    }
  }

  pub fn from_rag_ids(rag_ids: Vec<String>) -> Self {
    ChatTableChangeset {
      chat_id: Default::default(),
      // Serialize the Vec<String> to a JSON array string
      rag_ids: Some(serde_json::to_string(&rag_ids).unwrap_or_default()),
      name: None,
      metadata: None,
    }
  }
}

pub fn serialize_rag_ids(rag_ids: &[String]) -> String {
  serde_json::to_string(rag_ids).unwrap_or_default()
}

pub fn deserialize_rag_ids(rag_ids_str: &Option<String>) -> Vec<String> {
  match rag_ids_str {
    Some(str) => serde_json::from_str(str).unwrap_or_default(),
    None => Vec::new(),
  }
}

pub fn deserialize_chat_metadata<T>(metadata: &str) -> T
where
  T: serde::de::DeserializeOwned + Default,
{
  serde_json::from_str(metadata).unwrap_or_default()
}

pub fn serialize_chat_metadata<T>(metadata: &T) -> String
where
  T: Serialize,
{
  serde_json::to_string(metadata).unwrap_or_default()
}

pub fn upsert_chat(mut conn: DBConnection, new_chat: &ChatTable) -> QueryResult<usize> {
  diesel::insert_into(chat_table::table)
    .values(new_chat)
    .on_conflict(chat_table::chat_id)
    .do_update()
    .set((
      chat_table::created_at.eq(excluded(chat_table::created_at)),
      chat_table::name.eq(excluded(chat_table::name)),
      chat_table::metadata.eq(excluded(chat_table::metadata)),
      chat_table::rag_ids.eq(excluded(chat_table::rag_ids)),
    ))
    .execute(&mut *conn)
}

pub fn update_chat(
  conn: &mut SqliteConnection,
  changeset: ChatTableChangeset,
) -> QueryResult<usize> {
  let filter = dsl::chat_table.filter(chat_table::chat_id.eq(changeset.chat_id.clone()));
  let affected_row = diesel::update(filter).set(changeset).execute(conn)?;
  Ok(affected_row)
}

pub fn read_chat(mut conn: DBConnection, chat_id_val: &str) -> QueryResult<ChatTable> {
  let row = dsl::chat_table
    .filter(chat_table::chat_id.eq(chat_id_val))
    .first::<ChatTable>(&mut *conn)?;
  Ok(row)
}

pub fn read_chat_rag_ids(
  conn: &mut SqliteConnection,
  chat_id_val: &str,
) -> FlowyResult<Vec<String>> {
  let chat = dsl::chat_table
    .filter(chat_table::chat_id.eq(chat_id_val))
    .first::<ChatTable>(conn)?;

  Ok(deserialize_rag_ids(&chat.rag_ids))
}

pub fn read_chat_metadata(
  conn: &mut SqliteConnection,
  chat_id_val: &str,
) -> FlowyResult<ChatTableMetadata> {
  let metadata_str = dsl::chat_table
    .select(chat_table::metadata)
    .filter(chat_table::chat_id.eq(chat_id_val))
    .first::<String>(&mut *conn)?;
  Ok(deserialize_chat_metadata(&metadata_str))
}

#[allow(dead_code)]
pub fn update_chat_name(
  mut conn: DBConnection,
  chat_id_val: &str,
  new_name: &str,
) -> QueryResult<usize> {
  diesel::update(dsl::chat_table.filter(chat_table::chat_id.eq(chat_id_val)))
    .set(chat_table::name.eq(new_name))
    .execute(&mut *conn)
}

#[allow(dead_code)]
pub fn delete_chat(mut conn: DBConnection, chat_id_val: &str) -> QueryResult<usize> {
  diesel::delete(dsl::chat_table.filter(chat_table::chat_id.eq(chat_id_val))).execute(&mut *conn)
}
