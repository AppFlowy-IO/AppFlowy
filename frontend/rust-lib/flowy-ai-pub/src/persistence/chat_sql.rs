use diesel::sqlite::SqliteConnection;
use flowy_error::FlowyResult;
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{chat_table, chat_table::dsl},
  AsChangeset, DBConnection, ExpressionMethods, Identifiable, Insertable, QueryResult, Queryable,
};
use lib_infra::util::timestamp;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

#[derive(Clone, Default, Queryable, Insertable, Identifiable)]
#[diesel(table_name = chat_table)]
#[diesel(primary_key(chat_id))]
pub struct ChatTable {
  pub chat_id: String,
  pub created_at: i64,
  pub metadata: String,
  pub rag_ids: Option<String>,
  pub is_sync: bool,
  pub summary: String,
}

impl ChatTable {
  pub fn new(chat_id: String, metadata: Value, rag_ids: Vec<Uuid>, is_sync: bool) -> Self {
    let rag_ids = rag_ids.iter().map(|v| v.to_string()).collect::<Vec<_>>();
    let metadata = serialize_chat_metadata(&metadata);
    let rag_ids = Some(serialize_rag_ids(&rag_ids));
    Self {
      chat_id,
      created_at: timestamp(),
      metadata,
      rag_ids,
      is_sync,
      summary: "".to_string(),
    }
  }
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
  pub metadata: Option<String>,
  pub rag_ids: Option<String>,
  pub is_sync: Option<bool>,
  pub summary: Option<String>,
}

impl ChatTableChangeset {
  pub fn summary(chat_id: String, summary: String) -> Self {
    Self {
      chat_id,
      metadata: None,
      rag_ids: None,
      is_sync: None,
      summary: Some(summary),
    }
  }

  pub fn rag_ids(chat_id: String, rag_ids: Vec<String>) -> Self {
    let rag_ids = Some(serialize_rag_ids(&rag_ids));
    Self {
      chat_id,
      metadata: None,
      rag_ids,
      is_sync: None,
      summary: None,
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
      chat_table::metadata.eq(excluded(chat_table::metadata)),
      chat_table::rag_ids.eq(excluded(chat_table::rag_ids)),
      chat_table::is_sync.eq(excluded(chat_table::is_sync)),
    ))
    .execute(&mut *conn)
}

pub fn update_chat(mut conn: DBConnection, changeset: ChatTableChangeset) -> QueryResult<usize> {
  // Check if the chat exists
  let chat_exists = dsl::chat_table
    .filter(chat_table::chat_id.eq(&changeset.chat_id))
    .first::<ChatTable>(&mut *conn)
    .is_ok();

  if chat_exists {
    // Update existing chat
    let filter = dsl::chat_table.filter(chat_table::chat_id.eq(changeset.chat_id.clone()));
    diesel::update(filter).set(changeset).execute(&mut *conn)
  } else {
    // Create a new chat row with default values
    let chat = ChatTable {
      chat_id: changeset.chat_id.clone(),
      created_at: timestamp(),
      metadata: changeset.metadata.unwrap_or_else(|| "{}".to_string()),
      rag_ids: changeset.rag_ids,
      is_sync: changeset.is_sync.unwrap_or(false),
      summary: changeset.summary.unwrap_or_default(),
    };

    // Insert the new row
    diesel::insert_into(chat_table::table)
      .values(&chat)
      .execute(&mut *conn)
  }
}

pub fn update_chat_is_sync(
  mut conn: DBConnection,
  chat_id_val: &str,
  is_sync_val: bool,
) -> QueryResult<usize> {
  diesel::update(dsl::chat_table.filter(chat_table::chat_id.eq(chat_id_val)))
    .set(chat_table::is_sync.eq(is_sync_val))
    .execute(&mut *conn)
}

pub fn select_chat(mut conn: DBConnection, chat_id_val: &str) -> QueryResult<ChatTable> {
  let row = dsl::chat_table
    .filter(chat_table::chat_id.eq(chat_id_val))
    .first::<ChatTable>(&mut *conn)?;
  Ok(row)
}

pub fn select_chat_summary(conn: &mut DBConnection, chat_id_val: &Uuid) -> QueryResult<String> {
  let summary = dsl::chat_table
    .select(chat_table::summary)
    .filter(chat_table::chat_id.eq(chat_id_val.to_string()))
    .first::<String>(conn)?;
  Ok(summary)
}

pub fn select_chat_rag_ids(
  conn: &mut SqliteConnection,
  chat_id_val: &str,
) -> FlowyResult<Vec<String>> {
  let chat = dsl::chat_table
    .filter(chat_table::chat_id.eq(chat_id_val))
    .first::<ChatTable>(conn)?;

  Ok(deserialize_rag_ids(&chat.rag_ids))
}

pub fn select_chat_metadata(
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
pub fn delete_chat(mut conn: DBConnection, chat_id_val: &str) -> QueryResult<usize> {
  diesel::delete(dsl::chat_table.filter(chat_table::chat_id.eq(chat_id_val))).execute(&mut *conn)
}
