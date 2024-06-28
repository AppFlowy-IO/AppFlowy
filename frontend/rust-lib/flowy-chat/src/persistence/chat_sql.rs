use diesel::sqlite::SqliteConnection;
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{chat_table, chat_table::dsl},
  AsChangeset, DBConnection, ExpressionMethods, Identifiable, Insertable, QueryResult, Queryable,
};

#[derive(Clone, Default, Queryable, Insertable, Identifiable)]
#[diesel(table_name = chat_table)]
#[diesel(primary_key(chat_id))]
pub struct ChatTable {
  pub chat_id: String,
  pub created_at: i64,
  pub name: String,
  pub local_model_path: String,
  pub local_model_name: String,
  pub local_enabled: bool,
  pub sync_to_cloud: bool,
}

#[derive(AsChangeset, Identifiable, Default, Debug)]
#[diesel(table_name = chat_table)]
#[diesel(primary_key(chat_id))]
pub struct ChatTableChangeset {
  pub chat_id: String,
  pub name: Option<String>,
  pub local_model_path: Option<String>,
  pub local_model_name: Option<String>,
  pub local_enabled: Option<bool>,
  pub sync_to_cloud: Option<bool>,
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
pub fn update_chat_local_model(
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
