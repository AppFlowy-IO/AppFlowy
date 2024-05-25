use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{chat_table, chat_table::dsl},
  DBConnection, ExpressionMethods, Identifiable, Insertable, QueryResult, Queryable,
};

#[derive(Clone, Default, Queryable, Insertable, Identifiable)]
#[diesel(table_name = chat_table)]
#[diesel(primary_key(chat_id))]
pub struct ChatTable {
  pub chat_id: String,
  pub created_at: i64,
  pub name: String,
}

pub fn insert_chat(mut conn: DBConnection, new_chat: &ChatTable) -> QueryResult<usize> {
  diesel::insert_into(chat_table::table)
    .values(new_chat)
    .execute(&mut *conn)
}

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
