use flowy_error::{FlowyError, FlowyResult};
use flowy_sqlite::result::DatabaseErrorKind;
use flowy_sqlite::result::Error::DatabaseError;
use flowy_sqlite::schema::{upload_file_part, upload_file_table};
use flowy_sqlite::{
  diesel, AsChangeset, BoolExpressionMethods, DBConnection, ExpressionMethods, Identifiable,
  Insertable, OptionalExtension, QueryDsl, Queryable, RunQueryDsl, SqliteConnection,
};
use tracing::warn;

#[derive(Queryable, Insertable, AsChangeset, Identifiable, Debug, Clone)]
#[diesel(table_name = upload_file_table)]
#[diesel(primary_key(workspace_id, parent_dir, file_id))]
pub struct UploadFileTable {
  pub workspace_id: String,
  pub file_id: String,
  pub parent_dir: String,
  pub local_file_path: String,
  pub content_type: String,
  pub chunk_size: i32,
  pub num_chunk: i32,
  pub upload_id: String,
  pub created_at: i64,
  pub is_finish: bool,
}

#[derive(Queryable, Insertable, AsChangeset, Identifiable, Debug)]
#[diesel(table_name = upload_file_part)]
#[diesel(primary_key(upload_id, part_num))]
pub struct UploadFilePartTable {
  pub upload_id: String,
  pub e_tag: String,
  pub part_num: i32,
}

pub fn is_upload_file_exist(
  conn: &mut SqliteConnection,
  workspace_id: &str,
  parent_dir: &str,
  file_id: &str,
) -> FlowyResult<bool> {
  let result = upload_file_table::dsl::upload_file_table
    .filter(
      upload_file_table::workspace_id
        .eq(workspace_id)
        .and(upload_file_table::parent_dir.eq(parent_dir))
        .and(upload_file_table::file_id.eq(file_id)),
    )
    .first::<UploadFileTable>(conn)
    .optional()?;
  Ok(result.is_some())
}

pub fn insert_upload_file(
  mut conn: DBConnection,
  upload_file: &UploadFileTable,
) -> FlowyResult<()> {
  match diesel::insert_into(upload_file_table::table)
    .values(upload_file)
    .execute(&mut *conn)
  {
    Ok(_) => Ok(()),
    Err(DatabaseError(DatabaseErrorKind::UniqueViolation, _)) => Err(FlowyError::new(
      flowy_error::ErrorCode::DuplicateSqliteRecord,
      "Upload file already exists",
    )),
    Err(e) => Err(e.into()),
  }
}

pub fn update_upload_file_upload_id(
  mut conn: DBConnection,
  workspace_id: &str,
  parent_dir: &str,
  file_id: &str,
  upload_id: &str,
) -> FlowyResult<()> {
  diesel::update(
    upload_file_table::dsl::upload_file_table.filter(
      upload_file_table::workspace_id
        .eq(workspace_id)
        .and(upload_file_table::parent_dir.eq(parent_dir))
        .and(upload_file_table::file_id.eq(file_id)),
    ),
  )
  .set(upload_file_table::upload_id.eq(upload_id))
  .execute(&mut *conn)?;
  Ok(())
}

pub fn update_upload_file_completed(mut conn: DBConnection, upload_id: &str) -> FlowyResult<()> {
  diesel::update(
    upload_file_table::dsl::upload_file_table.filter(upload_file_table::upload_id.eq(upload_id)),
  )
  .set(upload_file_table::is_finish.eq(true))
  .execute(&mut *conn)?;
  Ok(())
}

pub fn is_upload_completed(
  conn: &mut SqliteConnection,
  workspace_id: &str,
  parent_dir: &str,
  file_id: &str,
) -> FlowyResult<bool> {
  let result = upload_file_table::dsl::upload_file_table
    .filter(
      upload_file_table::workspace_id
        .eq(workspace_id)
        .and(upload_file_table::parent_dir.eq(parent_dir))
        .and(upload_file_table::file_id.eq(file_id))
        .and(upload_file_table::is_finish.eq(true)),
    )
    .first::<UploadFileTable>(conn)
    .optional()?;
  Ok(result.is_some())
}

pub fn delete_upload_file(mut conn: DBConnection, upload_id: &str) -> FlowyResult<()> {
  conn.immediate_transaction(|conn| {
    diesel::delete(
      upload_file_table::dsl::upload_file_table.filter(upload_file_table::upload_id.eq(upload_id)),
    )
    .execute(&mut *conn)?;

    if let Err(err) = diesel::delete(
      upload_file_part::dsl::upload_file_part.filter(upload_file_part::upload_id.eq(upload_id)),
    )
    .execute(&mut *conn)
    {
      warn!("Failed to delete upload parts: {:?}", err)
    }

    Ok::<_, FlowyError>(())
  })?;

  Ok(())
}

pub fn delete_all_upload_parts(mut conn: DBConnection, upload_id: &str) -> FlowyResult<()> {
  diesel::delete(
    upload_file_part::dsl::upload_file_part.filter(upload_file_part::upload_id.eq(upload_id)),
  )
  .execute(&mut *conn)?;
  Ok(())
}

pub fn insert_upload_part(
  mut conn: DBConnection,
  upload_part: &UploadFilePartTable,
) -> FlowyResult<()> {
  diesel::insert_into(upload_file_part::table)
    .values(upload_part)
    .execute(&mut *conn)?;
  Ok(())
}

pub fn select_latest_upload_part(
  mut conn: DBConnection,
  upload_id: &str,
) -> FlowyResult<Option<UploadFilePartTable>> {
  let result = upload_file_part::dsl::upload_file_part
    .filter(upload_file_part::upload_id.eq(upload_id))
    .order(upload_file_part::part_num.desc())
    .first::<UploadFilePartTable>(&mut *conn)
    .optional()?;
  Ok(result)
}

pub fn select_upload_parts(
  conn: &mut SqliteConnection,
  upload_id: &str,
) -> FlowyResult<Vec<UploadFilePartTable>> {
  let results = upload_file_part::dsl::upload_file_part
    .filter(upload_file_part::upload_id.eq(upload_id))
    .load::<UploadFilePartTable>(conn)?;
  Ok(results)
}

pub fn batch_select_upload_file(
  mut conn: DBConnection,
  limit: i32,
  is_finish: bool,
) -> FlowyResult<Vec<UploadFileTable>> {
  let results = upload_file_table::dsl::upload_file_table
    .filter(upload_file_table::is_finish.eq(is_finish))
    .order(upload_file_table::created_at.desc())
    .limit(limit.into())
    .load::<UploadFileTable>(&mut *conn)?;

  Ok(results)
}

pub fn select_upload_file(
  conn: &mut SqliteConnection,
  workspace_id: &str,
  parent_dir: &str,
  file_id: &str,
) -> FlowyResult<Option<UploadFileTable>> {
  let result = upload_file_table::dsl::upload_file_table
    .filter(
      upload_file_table::workspace_id
        .eq(workspace_id)
        .and(upload_file_table::parent_dir.eq(parent_dir))
        .and(upload_file_table::file_id.eq(file_id)),
    )
    .first::<UploadFileTable>(conn)
    .optional()?;
  Ok(result)
}
