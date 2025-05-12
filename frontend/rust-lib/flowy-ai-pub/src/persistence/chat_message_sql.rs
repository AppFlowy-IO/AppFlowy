use crate::cloud::chat_dto::ChatAuthorType;
use crate::cloud::MessageCursor;
use client_api::entity::chat_dto::ChatMessage;
use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  diesel, insert_into,
  query_dsl::*,
  schema::{chat_message_table, chat_message_table::dsl},
  DBConnection, ExpressionMethods, Identifiable, Insertable, OptionalExtension, QueryResult,
  Queryable,
};

#[derive(Queryable, Insertable, Identifiable, Debug)]
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
  pub is_sync: bool,
}
impl ChatMessageTable {
  pub fn from_message(chat_id: String, message: ChatMessage, is_sync: bool) -> Self {
    ChatMessageTable {
      message_id: message.message_id,
      chat_id,
      content: message.content,
      created_at: message.created_at.timestamp(),
      author_type: message.author.author_type as i64,
      author_id: message.author.author_id.to_string(),
      reply_message_id: message.reply_message_id,
      metadata: Some(serde_json::to_string(&message.metadata).unwrap_or_default()),
      is_sync,
    }
  }
}

pub fn select_latest_user_message(
  mut conn: DBConnection,
  chat_id_val: &str,
  auth_type: ChatAuthorType,
) -> FlowyResult<ChatMessageTable> {
  dsl::chat_message_table
    .filter(chat_message_table::chat_id.eq(chat_id_val))
    .filter(chat_message_table::author_type.eq(auth_type as i64))
    .order(chat_message_table::created_at.desc())
    .first::<ChatMessageTable>(&mut *conn)
    .map_err(FlowyError::from)
}

pub fn update_chat_message_is_sync(
  mut conn: DBConnection,
  chat_id_val: &str,
  message_id_val: i64,
  is_sync_val: bool,
) -> FlowyResult<()> {
  diesel::update(chat_message_table::table)
    .filter(chat_message_table::chat_id.eq(chat_id_val))
    .filter(chat_message_table::message_id.eq(message_id_val))
    .set(chat_message_table::is_sync.eq(is_sync_val))
    .execute(&mut *conn)?;

  Ok(())
}

pub fn upsert_chat_messages(
  mut conn: DBConnection,
  new_messages: &[ChatMessageTable],
) -> FlowyResult<()> {
  //trace!("Upserting chat messages: {:?}", new_messages);
  conn.immediate_transaction(|conn| {
    for message in new_messages {
      let _ = insert_into(chat_message_table::table)
        .values(message)
        .on_conflict(chat_message_table::message_id)
        .do_update()
        .set((
          chat_message_table::content.eq(excluded(chat_message_table::content)),
          chat_message_table::metadata.eq(excluded(chat_message_table::metadata)),
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

pub struct ChatMessagesResult {
  pub messages: Vec<ChatMessageTable>,
  pub total_count: i64,
  pub has_more: bool,
}

pub fn select_chat_messages(
  mut conn: DBConnection,
  chat_id_val: &str,
  limit_val: u64,
  offset: MessageCursor,
) -> QueryResult<ChatMessagesResult> {
  let mut query = dsl::chat_message_table
    .filter(chat_message_table::chat_id.eq(chat_id_val))
    .into_boxed();

  match offset {
    MessageCursor::AfterMessageId(after_message_id) => {
      query = query.filter(chat_message_table::message_id.gt(after_message_id));
    },
    MessageCursor::BeforeMessageId(before_message_id) => {
      query = query.filter(chat_message_table::message_id.lt(before_message_id));
    },
    MessageCursor::Offset(offset_val) => {
      query = query.offset(offset_val as i64);
    },
    MessageCursor::NextBack => {},
  }

  // Get total count before applying limit
  let total_count = dsl::chat_message_table
    .filter(chat_message_table::chat_id.eq(chat_id_val))
    .count()
    .first::<i64>(&mut *conn)?;

  query = query
    .order((
      chat_message_table::created_at.desc(),
      chat_message_table::message_id.desc(),
    ))
    .limit(limit_val as i64);

  let messages: Vec<ChatMessageTable> = query.load::<ChatMessageTable>(&mut *conn)?;

  // Check if there are more messages
  let has_more = if let Some(last_message) = messages.last() {
    let remaining_count = dsl::chat_message_table
      .filter(chat_message_table::chat_id.eq(chat_id_val))
      .filter(chat_message_table::message_id.lt(last_message.message_id))
      .count()
      .first::<i64>(&mut *conn)?;

    remaining_count > 0
  } else {
    false
  };

  Ok(ChatMessagesResult {
    messages,
    total_count,
    has_more,
  })
}

pub fn total_message_count(mut conn: DBConnection, chat_id_val: &str) -> QueryResult<i64> {
  dsl::chat_message_table
    .filter(chat_message_table::chat_id.eq(chat_id_val))
    .count()
    .first::<i64>(&mut *conn)
}

pub fn select_message(
  mut conn: DBConnection,
  message_id_val: i64,
) -> QueryResult<Option<ChatMessageTable>> {
  let message = dsl::chat_message_table
    .filter(chat_message_table::message_id.eq(message_id_val))
    .first::<ChatMessageTable>(&mut *conn)
    .optional()?;
  Ok(message)
}

pub fn select_message_content(
  mut conn: DBConnection,
  message_id_val: i64,
) -> QueryResult<Option<String>> {
  let message = dsl::chat_message_table
    .filter(chat_message_table::message_id.eq(message_id_val))
    .select(chat_message_table::content)
    .first::<String>(&mut *conn)
    .optional()?;
  Ok(message)
}

pub fn select_answer_where_match_reply_message_id(
  mut conn: DBConnection,
  chat_id: &str,
  answer_message_id_val: i64,
) -> QueryResult<Option<ChatMessageTable>> {
  dsl::chat_message_table
    .filter(chat_message_table::reply_message_id.eq(answer_message_id_val))
    .filter(chat_message_table::chat_id.eq(chat_id))
    .first::<ChatMessageTable>(&mut *conn)
    .optional()
}
