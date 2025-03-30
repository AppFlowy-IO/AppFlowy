use super::folder_page_sql::get_page_by_id;
use client_api::entity::workspace_dto::FavoriteFolderView;
use diesel::prelude::*;
use diesel::RunQueryDsl;
use flowy_error::FlowyError;
use flowy_sqlite::schema::favorite_table;
use flowy_sqlite::DBConnection;
use flowy_sqlite::ExpressionMethods;

#[derive(Clone, Default, Queryable, Identifiable, Insertable, AsChangeset)]
#[diesel(table_name = favorite_table)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
pub struct FolderFavorite {
  pub(crate) id: String, // equals to view_id
  pub(crate) workspace_id: String,
  pub(crate) prev_id: Option<String>,
  pub(crate) favorited_at: i64,
  pub(crate) is_pinned: bool,
}

impl FolderFavorite {
  pub fn build_from_folder_view(
    favorite_folder_view: FavoriteFolderView,
    workspace_id: &str,
  ) -> Self {
    FolderFavorite {
      id: favorite_folder_view.view.view_id,
      workspace_id: workspace_id.to_string(),
      prev_id: None,
      favorited_at: favorite_folder_view.favorited_at.timestamp_millis(),
      is_pinned: favorite_folder_view.is_pinned,
    }
  }
}

/// Get a folder favorite by its id
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `page_id` - The id of the page
///
/// # Returns
///
/// A folder favorite
pub fn get_favorite_by_id(
  conn: &mut DBConnection,
  workspace_id: &str,
  page_id: &str,
) -> Result<FavoriteFolderView, FlowyError> {
  let folder_favorite = favorite_table::table
    .filter(
      favorite_table::id
        .eq(page_id)
        .and(favorite_table::workspace_id.eq(workspace_id)),
    )
    .first::<FolderFavorite>(conn)
    .map_err(|e| FlowyError::internal().with_context(format!("Failed to get favorite: {}", e)))?;

  // Get the folder page from folder_table
  let folder_view = get_page_by_id(conn, workspace_id, page_id, None, false)?;

  let favorited_at =
    chrono::DateTime::from_timestamp_millis(folder_favorite.favorited_at).unwrap_or_default();
  let is_pinned = folder_favorite.is_pinned;
  Ok(FavoriteFolderView {
    view: folder_view,
    favorited_at,
    is_pinned,
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
pub fn overwrite_favorite_table(
  conn: &mut DBConnection,
  folder_favorite_views: Vec<FavoriteFolderView>,
  workspace_id: &str,
) -> Result<usize, FlowyError> {
  let affected_rows = conn.transaction::<_, FlowyError, _>(|conn| {
    let mut total_rows = 0;

    for folder_favorite in folder_favorite_views {
      let folder_favorite = FolderFavorite::build_from_folder_view(folder_favorite, workspace_id);
      let result = diesel::insert_into(favorite_table::table)
        .values(&folder_favorite)
        .execute(conn)
        .map_err(|e| {
          FlowyError::internal().with_context(format!("Failed to overwrite favorite table: {}", e))
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
pub fn delete_folder_favorite(
  conn: &mut DBConnection,
  folder_favorite_views: Vec<FavoriteFolderView>,
  workspace_id: &str,
) -> Result<usize, FlowyError> {
  let affected_rows = conn.transaction::<_, FlowyError, _>(|conn| {
    let mut total_rows = 0;

    for folder_favorite in folder_favorite_views {
      let result = diesel::delete(favorite_table::table)
        .filter(
          favorite_table::id
            .eq(folder_favorite.view.view_id)
            .and(favorite_table::workspace_id.eq(workspace_id)),
        )
        .execute(conn)
        .map_err(|e| {
          FlowyError::internal().with_context(format!("Failed to delete folder favorite: {}", e))
        })?;

      total_rows += result;
    }

    Ok(total_rows)
  })?;

  Ok(affected_rows)
}
