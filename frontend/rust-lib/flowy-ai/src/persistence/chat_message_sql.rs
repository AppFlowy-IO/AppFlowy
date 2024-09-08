use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  diesel, insert_into,
  query_dsl::*,
  schema::{chat_message_table, chat_message_table::dsl},
  DBConnection, ExpressionMethods, Identifiable, Insertable, OptionalExtension, QueryResult,
  Queryable,
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
  pub reply_message_id: Option<i64>,
  pub metadata: Option<String>,
}

pub fn insert_chat_messages(
  mut conn: DBConnection,
  new_messages: &[ChatMessageTable],
) -> FlowyResult<()> {
  conn.immediate_transaction(|conn| {
    for message in new_messages {
      let _ = insert_into(chat_message_table::table)
        .values(message)
        .on_conflict(chat_message_table::message_id)
        .do_update()
        .set((
          chat_message_table::content.eq(excluded(chat_message_table::content)),
          chat_message_table::created_at.eq(excluded(chat_message_table::created_at)),
          chat_message_table::author_type.eq(excluded(chat_message_table::author_type)),
          chat_message_table::author_id.eq(excluded(chat_message_table::author_id)),
          chat_message_table::reply_message_id.eq(excluded(chat_message_table::reply_message_id)),
        ))
        .execute(conn)?;
    }
    Ok::<(), FlowyError>(())
  })?;

  Ok(())
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

pub fn select_single_message(
  mut conn: DBConnection,
  message_id_val: i64,
) -> QueryResult<Option<ChatMessageTable>> {
  let message = dsl::chat_message_table
    .filter(chat_message_table::message_id.eq(message_id_val))
    .first::<ChatMessageTable>(&mut *conn)
    .optional()?;
  Ok(message)
}
