use chrono::{NaiveDateTime, Utc};
use diesel::sqlite::SqliteConnection;
use flowy_error::FlowyResult;
use flowy_sqlite::internal::derives::multiconnection::chrono;
use flowy_sqlite::upsert::excluded;
use flowy_sqlite::{
  diesel,
  query_dsl::*,
  schema::{collab_table, collab_table::dsl},
  AsChangeset, ExpressionMethods, Identifiable, Insertable, Queryable,
};

#[derive(Clone, Debug, Queryable, Insertable, AsChangeset, Identifiable)]
#[diesel(table_name = collab_table)]
#[diesel(primary_key(oid))]
pub struct CollabTable {
  pub oid: String,
  pub content: String,
  pub collab_type: i16,
  pub updated_at: NaiveDateTime,
  pub indexed_at: Option<NaiveDateTime>,
  pub deleted_at: Option<NaiveDateTime>,
}

impl CollabTable {
  pub fn new(oid: String, collab_type: i16, content: String) -> Self {
    Self {
      oid,
      content,
      collab_type,
      updated_at: Utc::now().naive_utc(),
      indexed_at: None,
      deleted_at: None,
    }
  }
}

pub fn upsert_collab(conn: &mut SqliteConnection, row: CollabTable) -> FlowyResult<()> {
  diesel::insert_into(collab_table::table)
    .values(row)
    .on_conflict(collab_table::oid)
    .do_update()
    .set((
      collab_table::content.eq(excluded(collab_table::content)),
      collab_table::updated_at.eq(excluded(collab_table::updated_at)),
      collab_table::deleted_at.eq(excluded(collab_table::deleted_at)),
      collab_table::indexed_at.eq(excluded(collab_table::indexed_at)),
    ))
    .execute(conn)?;

  Ok(())
}

pub fn select_unindexed_collab(
  conn: &mut SqliteConnection,
  limit: i64,
) -> FlowyResult<Vec<CollabTable>> {
  let rows = collab_table::table
    .filter(collab_table::deleted_at.is_null())
    .order(collab_table::updated_at.desc())
    .limit(limit)
    .load::<CollabTable>(conn)?;

  Ok(rows)
}

pub fn update_collab_index_at(
  conn: &mut SqliteConnection,
  oid_val: &str,
  indexed_at: NaiveDateTime,
) -> FlowyResult<()> {
  diesel::update(dsl::collab_table.filter(collab_table::oid.eq(oid_val)))
    .set(collab_table::indexed_at.eq(Some(indexed_at)))
    .execute(conn)?;
  Ok(())
}

pub fn soft_delete_collab(conn: &mut SqliteConnection, oid_val: &str) -> FlowyResult<()> {
  let time = Utc::now().naive_utc();
  diesel::update(dsl::collab_table.filter(collab_table::oid.eq(oid_val)))
    .set(collab_table::deleted_at.eq(Some(time)))
    .execute(conn)?;
  Ok(())
}

pub fn delete_collab(conn: &mut SqliteConnection, oid: &str) -> FlowyResult<()> {
  diesel::delete(dsl::collab_table.filter(collab_table::oid.eq(oid))).execute(conn)?;
  Ok(())
}
