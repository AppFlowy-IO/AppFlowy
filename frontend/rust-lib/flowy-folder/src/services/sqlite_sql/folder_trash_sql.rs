use std::collections::VecDeque;

use super::folder_page_sql::get_page_by_id;
use client_api::entity::workspace_dto::FolderView;
use client_api::entity::workspace_dto::TrashFolderView;
use diesel::prelude::*;
use diesel::RunQueryDsl;
use flowy_error::FlowyError;
use flowy_sqlite::schema::trash_table;
use flowy_sqlite::DBConnection;
use flowy_sqlite::ExpressionMethods;

#[derive(Clone, Default, Queryable, Identifiable, Insertable, AsChangeset)]
#[diesel(table_name = trash_table)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
pub struct FolderTrash {
  pub(crate) id: String, // equals to view_id
  pub(crate) workspace_id: String,
  pub(crate) prev_id: Option<String>,
  pub(crate) deleted_at: i64,
}

impl FolderTrash {
  pub fn build_from_folder_view(trash_folder_view: TrashFolderView, workspace_id: &str) -> Self {
    FolderTrash {
      id: trash_folder_view.view.view_id,
      workspace_id: workspace_id.to_string(),
      prev_id: None,
      deleted_at: trash_folder_view.deleted_at.timestamp_millis(),
    }
  }
}

/// Get a folder trash by its id
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `page_id` - The id of the page
///
/// # Returns
///
/// A folder trash
pub fn get_trash_by_id(
  conn: &mut DBConnection,
  workspace_id: &str,
  page_id: &str,
) -> Result<TrashFolderView, FlowyError> {
  let folder_trash = trash_table::table
    .filter(
      trash_table::id
        .eq(page_id)
        .and(trash_table::workspace_id.eq(workspace_id)),
    )
    .first::<FolderTrash>(conn)
    .map_err(|e| FlowyError::internal().with_context(format!("Failed to get trash: {}", e)))?;

  // Get the folder page from folder_table
  let folder_view = get_page_by_id(conn, workspace_id, page_id, None, false)?;

  let delete_at =
    chrono::DateTime::from_timestamp_millis(folder_trash.deleted_at).unwrap_or_default();
  Ok(TrashFolderView {
    view: folder_view,
    deleted_at: delete_at,
  })
}

/// Overwrite the folder table with a new folder view
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `folder_view` - The folder view to overwrite
/// * `workspace_id` - The id of the workspace
/// * `parent_id` - The id of the parent page
///
/// # Returns
///
/// The number of rows affected by the operation
pub fn overwrite_trash_table(
  conn: &mut DBConnection,
  folder_trash_views: Vec<TrashFolderView>,
  workspace_id: &str,
) -> Result<usize, FlowyError> {
  let affected_rows = conn.transaction::<_, FlowyError, _>(|conn| {
    let mut total_rows = 0;

    for folder_trash in folder_trash_views {
      let folder_trash = FolderTrash::build_from_folder_view(folder_trash, workspace_id);
      let result = diesel::insert_into(trash_table::table)
        .values(&folder_trash)
        .execute(conn)
        .map_err(|e| {
          FlowyError::internal().with_context(format!("Failed to overwrite trash table: {}", e))
        })?;

      total_rows += result;
    }

    Ok(total_rows)
  })?;

  Ok(affected_rows)
}

/// Delete the TrashFolderViews from the database
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `workspace_id` - The id of the workspace
/// * `folder_trash_views` - The folder trash views to delete
///
/// # Returns
///
/// The number of rows affected by the operation
pub fn delete_folder_trash(
  conn: &mut DBConnection,
  folder_trash_views: Vec<TrashFolderView>,
) -> Result<usize, FlowyError> {
  let affected_rows = conn.transaction::<_, FlowyError, _>(|conn| {
    let mut total_rows = 0;

    for folder_trash in folder_trash_views {
      let result = diesel::delete(trash_table::table)
        .filter(trash_table::id.eq(folder_trash.view.view_id))
        .execute(conn)
        .map_err(|e| {
          FlowyError::internal().with_context(format!("Failed to delete folder trash: {}", e))
        })?;

      total_rows += result;
    }

    Ok(total_rows)
  })?;

  Ok(affected_rows)
}
