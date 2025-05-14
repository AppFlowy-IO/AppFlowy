use diesel::sqlite::SqliteConnection;
use flowy_error::FlowyResult;
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  ExpressionMethods, Identifiable, Insertable, Queryable, diesel,
  query_dsl::*,
  schema::{local_ai_model_table, local_ai_model_table::dsl},
};

#[derive(Clone, Default, Queryable, Insertable, Identifiable)]
#[diesel(table_name = local_ai_model_table)]
#[diesel(primary_key(name))]
pub struct LocalAIModelTable {
  pub name: String,
  pub model_type: i16,
}

#[derive(Clone, Debug, Copy)]
pub enum ModelType {
  Embedding = 0,
  Chat = 1,
}

impl From<i16> for ModelType {
  fn from(value: i16) -> Self {
    match value {
      0 => ModelType::Embedding,
      1 => ModelType::Chat,
      _ => ModelType::Embedding,
    }
  }
}

pub fn select_local_ai_model(conn: &mut SqliteConnection, name: &str) -> Option<LocalAIModelTable> {
  local_ai_model_table::table
    .filter(dsl::name.eq(name))
    .first::<LocalAIModelTable>(conn)
    .ok()
}

pub fn upsert_local_ai_model(
  conn: &mut SqliteConnection,
  row: &LocalAIModelTable,
) -> FlowyResult<()> {
  diesel::insert_into(local_ai_model_table::table)
    .values(row)
    .on_conflict(local_ai_model_table::name)
    .do_update()
    .set((local_ai_model_table::model_type.eq(excluded(local_ai_model_table::model_type)),))
    .execute(conn)?;

  Ok(())
}
