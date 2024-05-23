use flowy_sqlite::query_dsl::methods::OrderDsl;
use flowy_sqlite::schema::chat_message_table::dsl::chat_message_table;
use flowy_sqlite::schema::chat_message_table::{content, created_at, message_id};
use flowy_sqlite::schema::chat_table::dsl::chat_table;
use flowy_sqlite::schema::chat_table::{chat_id, name};
use flowy_sqlite::{
  diesel, ExpressionMethods, Insertable, QueryResult, Queryable, RunQueryDsl, SqliteConnection,
};

pub fn create_chat(conn: &mut SqliteConnection, new_chat: Chat) -> QueryResult<usize> {
  diesel::insert_into(chat_table)
    .values(&new_chat)
    .execute(conn)
}

pub fn read_chat(conn: &SqliteConnection, chat_id_val: &str) -> QueryResult<Chat> {
  chat_table.filter(chat_id.eq(chat_id_val)).first(conn)
}

pub fn update_chat_name(
  conn: &SqliteConnection,
  chat_id_val: &str,
  new_name: &str,
) -> QueryResult<usize> {
  diesel::update(chat_table.filter(chat_id.eq(chat_id_val)))
    .set(name.eq(new_name))
    .execute(conn)
}

pub fn delete_chat(conn: &SqliteConnection, chat_id_val: &str) -> QueryResult<usize> {
  diesel::delete(chat_table.filter(chat_id.eq(chat_id_val))).execute(conn)
}

pub fn create_chat_message(
  conn: &mut SqliteConnection,
  new_message: ChatMessage,
) -> QueryResult<usize> {
  diesel::insert_into(chat_message_table)
    .values(&new_message)
    .execute(conn)
}

pub fn read_chat_message(conn: &SqliteConnection, message_id_val: i32) -> QueryResult<ChatMessage> {
  chat_message_table
    .filter(message_id.eq(message_id_val))
    .first(conn)
}

pub fn update_chat_message_content(
  conn: &SqliteConnection,
  message_id_val: i32,
  new_content: &str,
) -> QueryResult<usize> {
  diesel::update(chat_message_table.filter(message_id.eq(message_id_val)))
    .set(content.eq(new_content))
    .execute(conn)
}

pub fn read_all_chat_messages(
  conn: &SqliteConnection,
  chat_id_val: &str,
  limit_val: i64,
) -> QueryResult<Vec<ChatMessage>> {
  chat_message_table
    .filter(chat_id.eq(chat_id_val))
    .order(created_at.asc())
    .limit(limit_val)
    .load::<ChatMessage>(conn)
}

#[derive(Queryable, Insertable)]
#[table_name = "chat_table"]
pub struct Chat {
  pub chat_id: String,
  pub created_at: i64,
  pub name: String,
}

#[derive(Queryable, Insertable)]
#[table_name = "chat_message_table"]
pub struct ChatMessage {
  pub message_id: i64,
  pub chat_id: String,
  pub content: String,
  pub created_at: i64,
}
