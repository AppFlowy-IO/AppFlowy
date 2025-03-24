use std::collections::VecDeque;

use client_api::entity::workspace_dto::FolderView;
use diesel::prelude::*;
use diesel::RunQueryDsl;
use flowy_error::FlowyError;
use flowy_sqlite::schema::folder_table;
use flowy_sqlite::DBConnection;
use flowy_sqlite::ExpressionMethods;

#[derive(Clone, Default, Queryable, Identifiable, Insertable)]
#[diesel(table_name = folder_table)]
#[diesel(check_for_backend(diesel::sqlite::Sqlite))]
pub struct FolderPage {
  pub(crate) id: String, // equals to view_id
  pub(crate) workspace_id: String,
  pub(crate) name: String,
  pub(crate) icon: Option<String>,
  pub(crate) is_space: bool,
  pub(crate) is_private: bool,
  pub(crate) is_published: bool,
  pub(crate) is_favorite: bool,
  pub(crate) layout: i32,
  pub(crate) created_at: String,
  pub(crate) last_edited_time: String,
  pub(crate) is_locked: Option<bool>,
  pub(crate) parent_id: Option<String>,
  pub(crate) sync_status: String,
  pub(crate) last_modified_time: String,
  pub(crate) extra: Option<String>,
}

impl FolderPage {
  pub fn build_from_folder_view(
    folder_view: FolderView,
    workspace_id: &str,
    parent_id: Option<String>,
  ) -> Self {
    FolderPage {
      id: folder_view.view_id,
      workspace_id: workspace_id.to_string(),
      name: folder_view.name,
      icon: serde_json::to_string(&folder_view.icon).ok(),
      is_space: folder_view.is_space,
      is_private: folder_view.is_private,
      is_published: folder_view.is_published,
      is_favorite: folder_view.is_favorite,
      layout: folder_view.layout as i32,
      created_at: chrono::Utc::now().to_rfc3339(), // verify if this is correct
      last_edited_time: chrono::Utc::now().to_rfc3339(), // verify if this is correct
      is_locked: folder_view.is_locked,
      parent_id,
      sync_status: "synced".to_string(),
      last_modified_time: chrono::Utc::now().to_rfc3339(),
      extra: serde_json::to_string(&folder_view.extra).ok(),
    }
  }
}

impl From<FolderPage> for FolderView {
  fn from(folder: FolderPage) -> Self {
    // Parse created_at and last_edited_time
    let created_at = chrono::NaiveDateTime::parse_from_str(&folder.created_at, "%Y-%m-%d %H:%M:%S")
      .unwrap_or_default()
      .and_utc();

    let last_edited_time =
      chrono::NaiveDateTime::parse_from_str(&folder.last_edited_time, "%Y-%m-%d %H:%M:%S")
        .unwrap_or_default()
        .and_utc();

    // Parse icon
    let icon = folder.icon.as_ref().and_then(|icon_str| {
      if icon_str.is_empty() {
        None
      } else {
        serde_json::from_str(icon_str).ok()
      }
    });

    // Parse extra
    let extra = folder.extra.and_then(|extra_str| {
      if !extra_str.is_empty() {
        serde_json::from_str(&extra_str).ok()
      } else {
        None
      }
    });

    // Convert layout from i32 to ViewLayout enum
    let layout = match folder.layout {
      0 => client_api::entity::workspace_dto::ViewLayout::Document,
      1 => client_api::entity::workspace_dto::ViewLayout::Grid,
      2 => client_api::entity::workspace_dto::ViewLayout::Board,
      3 => client_api::entity::workspace_dto::ViewLayout::Calendar,
      4 => client_api::entity::workspace_dto::ViewLayout::Chat,
      _ => client_api::entity::workspace_dto::ViewLayout::Document, // fallback to Document
    };

    FolderView {
      view_id: folder.id,
      parent_view_id: folder.parent_id.unwrap_or_default(),
      name: folder.name,
      icon,
      is_space: folder.is_space,
      is_private: folder.is_private,
      is_published: folder.is_published,
      is_favorite: folder.is_favorite,
      layout,
      created_at,
      created_by: None,
      last_edited_by: None,
      last_edited_time,
      is_locked: folder.is_locked,
      extra,
      children: Vec::new(), // Initialize with empty vector
    }
  }
}

/// Get a folder view by its id
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `page_id` - The id of the page
/// * `depth` - The maximum depth to retrieve children. If None, all children are retrieved.
///
/// # Returns
///
/// A folder view that contains the folder and its children up to the specified depth
pub fn get_page_by_id(
  conn: &mut DBConnection,
  workspace_id: &str,
  page_id: &str,
  depth: Option<u32>,
) -> Result<FolderView, FlowyError> {
  let folder_page = folder_table::table
    .filter(
      folder_table::id
        .eq(page_id)
        .and(folder_table::workspace_id.eq(workspace_id)),
    )
    .first::<FolderPage>(conn)
    .map_err(|e| {
      FlowyError::internal().with_context(format!("Failed to get folder page: {}", e))
    })?;

  let mut folder_view: FolderView = folder_page.into();
  folder_view.children = get_page_children_by_id(conn, workspace_id, page_id, depth)?;
  Ok(folder_view)
}

/// Get all children of a page up to a specified depth
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `workspace_id` - The id of the workspace
/// * `parent_id` - The id of the parent page
/// * `depth` - The maximum depth to retrieve. If None, all children are retrieved.
///             If Some(0), no children are retrieved.
///
/// # Returns
///
/// A vector of FolderView that contains the children of the page up to the specified depth
fn get_page_children_by_id(
  conn: &mut DBConnection,
  workspace_id: &str,
  parent_id: &str,
  depth: Option<u32>,
) -> Result<Vec<FolderView>, FlowyError> {
  // If depth is Some(0), we don't need to retrieve any children
  if depth == Some(0) {
    return Ok(Vec::new());
  }

  let children_pages = folder_table::table
    .filter(
      folder_table::parent_id
        .eq(parent_id)
        .and(folder_table::workspace_id.eq(workspace_id)),
    )
    .load::<FolderPage>(conn)
    .map_err(|e| FlowyError::internal().with_context(format!("Failed to get children: {}", e)))?;

  let mut children_views = Vec::with_capacity(children_pages.len());

  for child_page in children_pages {
    let child_id = child_page.id.clone();
    let mut child_view: FolderView = child_page.into();

    let next_depth = depth.map(|d| d - 1);

    child_view.children = get_page_children_by_id(conn, workspace_id, &child_id, next_depth)?;
    children_views.push(child_view);
  }

  Ok(children_views)
}

/// Insert a FolderView and its children into the database
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `folder_view` - The folder view to insert
/// * `workspace_id` - The id of the workspace
/// * `parent_id` - The id of the parent page
///
/// # Returns
///
/// The number of rows affected by the operation
pub fn insert_folder_view_with_children(
  conn: &mut DBConnection,
  folder_view: FolderView,
  workspace_id: &str,
  parent_id: Option<String>,
) -> Result<usize, FlowyError> {
  // 1. flatten the folder view
  let folder_pages = flatten_folder_view(folder_view, workspace_id, parent_id)?;
  // 2. insert the folder pages
  let affected_rows = diesel::insert_into(folder_table::table)
    .values(folder_pages)
    .execute(conn)
    .map_err(|e| {
      FlowyError::internal().with_context(format!("Failed to insert folder pages: {}", e))
    })?;
  Ok(affected_rows)
}

/// Flatten a folder view and its children recursively into a folder page list
///
/// # Arguments
///
/// * `folder_view` - The folder view to flatten
/// * `workspace_id` - The id of the workspace
/// * `parent_id` - The id of the parent page
///
/// # Returns
///
/// A vector of folder pages
pub fn flatten_folder_view(
  folder_view: FolderView,
  workspace_id: &str,
  parent_id: Option<String>,
) -> Result<Vec<FolderPage>, FlowyError> {
  let mut folder_pages = Vec::new();
  let mut queue = VecDeque::new();

  // Store the view and its parent ID together in the queue
  queue.push_back((folder_view, parent_id));

  while let Some((current_view, current_parent_id)) = queue.pop_front() {
    // Use the provided parent_id instead of the view's own ID
    let folder_page =
      FolderPage::build_from_folder_view(current_view.clone(), workspace_id, current_parent_id);
    folder_pages.push(folder_page);

    // For each child, use the current view's ID as their parent ID
    for child in current_view.children {
      queue.push_back((child, Some(current_view.view_id.clone())));
    }
  }
  Ok(folder_pages)
}
