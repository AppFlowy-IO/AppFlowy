use diesel::sqlite::SqliteConnection;
use flowy_error::FlowyResult;
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{index_collab_record_table, index_collab_record_table::dsl},
  AsChangeset, ExpressionMethods, Identifiable, Insertable, Queryable,
};

#[derive(Clone, Debug, Queryable, Insertable, AsChangeset, Identifiable)]
#[diesel(table_name = index_collab_record_table)]
#[diesel(primary_key(oid))]
pub struct IndexCollabRecordTable {
  pub oid: String,
  pub workspace_id: String,
  pub content_hash: String,
}

impl IndexCollabRecordTable {
  pub fn new(workspace_id: String, oid: String, content_hash: String) -> Self {
    Self {
      workspace_id,
      oid,
      content_hash,
    }
  }
}

pub fn batch_upsert_index_collab(
  conn: &mut SqliteConnection,
  rows: Vec<IndexCollabRecordTable>,
) -> FlowyResult<()> {
  if rows.is_empty() {
    return Ok(());
  }

  conn.immediate_transaction::<_, diesel::result::Error, _>(|conn| {
    for row in rows {
      diesel::insert_into(index_collab_record_table::table)
        .values(&row)
        .on_conflict(index_collab_record_table::oid)
        .do_update()
        .set(
          index_collab_record_table::content_hash
            .eq(excluded(index_collab_record_table::content_hash)),
        )
        .execute(conn)?;
    }
    Ok(())
  })?;

  Ok(())
}

pub fn upsert_index_collab(
  conn: &mut SqliteConnection,
  row: IndexCollabRecordTable,
) -> FlowyResult<()> {
  diesel::insert_into(index_collab_record_table::table)
    .values(row)
    .on_conflict(index_collab_record_table::oid)
    .do_update()
    .set((
      index_collab_record_table::content_hash.eq(excluded(index_collab_record_table::content_hash)),
    ))
    .execute(conn)?;

  Ok(())
}

pub fn select_indexed_collab_ids(
  conn: &mut SqliteConnection,
  workspace_id: String,
) -> FlowyResult<Vec<String>> {
  let result = index_collab_record_table::table
    .filter(index_collab_record_table::workspace_id.eq(workspace_id))
    .select(dsl::oid)
    .load::<String>(conn)?;

  Ok(result)
}

pub fn select_indexed_collab(
  conn: &mut SqliteConnection,
  workspace_id: String,
  limit: i64,
  offset: i64,
) -> FlowyResult<Vec<IndexCollabRecordTable>> {
  let result = index_collab_record_table::table
    .filter(index_collab_record_table::workspace_id.eq(workspace_id))
    .limit(limit)
    .offset(offset)
    .load::<IndexCollabRecordTable>(conn)?;

  Ok(result)
}
