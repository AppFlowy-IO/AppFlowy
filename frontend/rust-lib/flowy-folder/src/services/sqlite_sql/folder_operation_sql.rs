use diesel::prelude::*;
use diesel::RunQueryDsl;
use flowy_error::FlowyError;
use flowy_sqlite::schema::folder_operation_table;
use flowy_sqlite::DBConnection;
use flowy_sqlite::ExpressionMethods;

use crate::sync_worker::sync_worker_op_name::HTTP_STATUS_PENDING;

#[derive(Clone, Default, Queryable, Identifiable, Insertable, AsChangeset)]
#[diesel(table_name = folder_operation_table)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
pub struct FolderOperation {
  pub(crate) id: i32, // Auto-incrementing primary key
  pub(crate) workspace_id: String,
  pub(crate) page_id: Option<String>,
  pub(crate) name: String,
  pub(crate) method: String,
  pub(crate) status: String,
  pub(crate) payload: Option<String>,
  pub(crate) timestamp: i64,
}

impl FolderOperation {
  pub fn new(
    workspace_id: &str,
    page_id: Option<&str>,
    name: &str,
    method: &str,
    status: &str,
    payload: Option<&str>,
    timestamp: i64,
  ) -> Self {
    Self {
      id: 0, // Will be set by SQLite
      workspace_id: workspace_id.to_string(),
      page_id: page_id.map(|s| s.to_string()),
      name: name.to_string(),
      method: method.to_string(),
      status: status.to_string(),
      payload: payload.map(|s| s.to_string()),
      timestamp,
    }
  }

  pub fn pending(
    workspace_id: &str,
    page_id: Option<&str>,
    name: &str,
    method: &str,
    payload: Option<&str>,
  ) -> Self {
    Self::new(
      workspace_id,
      page_id,
      name,
      method,
      HTTP_STATUS_PENDING,
      payload,
      chrono::Utc::now().timestamp_millis(),
    )
  }
}

/// Upsert a new folder operation and return the ID of the inserted operation
pub fn upsert_operation(
  conn: &mut DBConnection,
  operation: FolderOperation,
) -> Result<i32, FlowyError> {
  let _ = diesel::insert_into(folder_operation_table::table)
    .values(&operation)
    .on_conflict(folder_operation_table::id)
    .do_update()
    .set(&operation)
    .execute(conn)
    .map_err(|e| {
      FlowyError::internal().with_context(format!("Failed to insert folder operation: {}", e))
    })?;

  // Get the last inserted ID
  let last_id = diesel::select(diesel::dsl::sql::<diesel::sql_types::Integer>(
    "last_insert_rowid()",
  ))
  .first(conn)
  .map_err(|e| {
    FlowyError::internal().with_context(format!("Failed to get last inserted ID: {}", e))
  })?;

  Ok(last_id)
}

/// Remove a folder operation by ID
pub fn remove_operation(conn: &mut DBConnection, id: i32) -> Result<(), FlowyError> {
  let _ = diesel::delete(folder_operation_table::table.filter(folder_operation_table::id.eq(id)))
    .execute(conn)
    .map_err(|e| {
      FlowyError::internal().with_context(format!("Failed to remove folder operation: {}", e))
    })?;

  Ok(())
}

/// Get all folder operations by workspace ID
pub fn get_operations_by_workspace_id(
  conn: &mut DBConnection,
  workspace_id: &str,
) -> Result<Vec<FolderOperation>, FlowyError> {
  let operations = folder_operation_table::table
    .filter(folder_operation_table::workspace_id.eq(workspace_id))
    .load::<FolderOperation>(conn)
    .map_err(|e| {
      FlowyError::internal().with_context(format!("Failed to get folder operations: {}", e))
    })?;
  Ok(operations)
}

/// Get all folder operations by status
pub fn get_pending_operations_by_workspace_id(
  conn: &mut DBConnection,
  workspace_id: &str,
) -> Result<Vec<FolderOperation>, FlowyError> {
  let operations = folder_operation_table::table
      .filter(folder_operation_table::workspace_id.eq(workspace_id))
      .filter(folder_operation_table::status.eq("pending".to_string()))
      .order(folder_operation_table::timestamp.asc()) // Process older operations first
      .load::<FolderOperation>(conn)
      .map_err(|e| {
        FlowyError::internal().with_context(format!("Failed to get folder operations by status: {}", e))
      })?;
  Ok(operations)
}

/// Update the status of a folder operation
pub fn update_operation_status(
  conn: &mut DBConnection,
  id: i32,
  new_status: String,
) -> Result<(), FlowyError> {
  let _ = diesel::update(folder_operation_table::table.filter(folder_operation_table::id.eq(id)))
    .set(folder_operation_table::status.eq(new_status))
    .execute(conn)
    .map_err(|e| {
      FlowyError::internal()
        .with_context(format!("Failed to update folder operation status: {}", e))
    })?;
  Ok(())
}
