use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{chat_message_table, chat_message_table::dsl},
  DBConnection, ExpressionMethods, Identifiable, Insertable, QueryResult, Queryable,
};

#[derive(Queryable, Insertable, Identifiable)]
#[diesel(table_name = chat_message_table)]
#[diesel(primary_key(message_id))]
pub struct ChatMessageTable {
  pub message_id: i64,
  pub chat_id: String,
  pub content: String,
  pub created_at: i64,
  pub author_type: i64,
  pub author_id: String,
}

pub fn insert_chat_messages(
  mut conn: DBConnection,
  new_messages: &[ChatMessageTable],
) -> QueryResult<usize> {
  diesel::insert_into(chat_message_table::table)
    .values(new_messages)
    .execute(&mut *conn)
}

pub fn select_chat_messages(
  mut conn: DBConnection,
  chat_id_val: &str,
  limit_val: i64,
  after_message_id: Option<i64>,
  before_message_id: Option<i64>,
) -> QueryResult<Vec<ChatMessageTable>> {
  let mut query = dsl::chat_message_table
    .filter(chat_message_table::chat_id.eq(chat_id_val))
    .into_boxed();
  if let Some(after_message_id) = after_message_id {
    query = query.filter(chat_message_table::message_id.gt(after_message_id));
  }

  if let Some(before_message_id) = before_message_id {
    query = query.filter(chat_message_table::message_id.lt(before_message_id));
  }
  query = query
    .order((chat_message_table::message_id.desc(),))
    .limit(limit_val);

  let messages: Vec<ChatMessageTable> = query.load::<ChatMessageTable>(&mut *conn)?;
  Ok(messages)
}
