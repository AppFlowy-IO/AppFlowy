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
  pub local_files: String,
  pub metadata: String,
  pub local_enabled: bool,
  pub sync_to_cloud: bool,
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
  pub local_files: Option<String>,
  pub metadata: Option<String>,
  pub local_enabled: Option<bool>,
  pub sync_to_cloud: Option<bool>,
}

impl ChatTableChangeset {
  pub fn from_metadata(metadata: ChatTableMetadata) -> Self {
    ChatTableChangeset {
      metadata: serde_json::to_string(&metadata).ok(),
      ..Default::default()
    }
  }
}

pub fn insert_chat(mut conn: DBConnection, new_chat: &ChatTable) -> QueryResult<usize> {
  diesel::insert_into(chat_table::table)
    .values(new_chat)
    .on_conflict(chat_table::chat_id)
    .do_update()
    .set((
      chat_table::created_at.eq(excluded(chat_table::created_at)),
      chat_table::name.eq(excluded(chat_table::name)),
    ))
    .execute(&mut *conn)
}

#[allow(dead_code)]
pub fn update_chat(
  conn: &mut SqliteConnection,
  changeset: ChatTableChangeset,
) -> QueryResult<usize> {
  let filter = dsl::chat_table.filter(chat_table::chat_id.eq(changeset.chat_id.clone()));
  let affected_row = diesel::update(filter).set(changeset).execute(conn)?;
  Ok(affected_row)
}

#[allow(dead_code)]
pub fn read_chat(mut conn: DBConnection, chat_id_val: &str) -> QueryResult<ChatTable> {
  let row = dsl::chat_table
    .filter(chat_table::chat_id.eq(chat_id_val))
    .first::<ChatTable>(&mut *conn)?;
  Ok(row)
}

#[allow(dead_code)]
pub fn read_chat_metadata(
  conn: &mut SqliteConnection,
  chat_id_val: &str,
) -> FlowyResult<ChatTableMetadata> {
  let metadata_str = dsl::chat_table
    .select(chat_table::metadata)
    .filter(chat_table::chat_id.eq(chat_id_val))
    .first::<String>(&mut *conn)?;
  let value = serde_json::from_str(&metadata_str).unwrap_or_default();
  Ok(value)
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
