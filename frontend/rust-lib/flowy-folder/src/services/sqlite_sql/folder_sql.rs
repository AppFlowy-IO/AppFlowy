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
  page_id: &str,
  depth: Option<usize>,
) -> Result<FolderView, FlowyError> {
  let folder_page = folder_table::table
    .filter(folder_table::id.eq(page_id))
    .first::<FolderPage>(conn)
    .map_err(|e| {
      FlowyError::internal().with_context(format!("Failed to get folder page: {}", e))
    })?;

  let mut folder_view: FolderView = folder_page.into();
  folder_view.children = get_page_children_by_id(conn, page_id, depth)?;
  Ok(folder_view)
}

/// Get all children of a page up to a specified depth
///
/// # Arguments
///
/// * `conn` - The database connection
/// * `parent_id` - The id of the parent page
/// * `depth` - The maximum depth to retrieve. If None, all children are retrieved.
///             If Some(0), no children are retrieved.
///
/// # Returns
///
/// A vector of FolderView that contains the children of the page up to the specified depth
fn get_page_children_by_id(
  conn: &mut DBConnection,
  parent_id: &str,
  depth: Option<usize>,
) -> Result<Vec<FolderView>, FlowyError> {
  // If depth is Some(0), we don't need to retrieve any children
  if depth == Some(0) {
    return Ok(Vec::new());
  }

  let children_pages = folder_table::table
    .filter(folder_table::parent_id.eq(parent_id))
    .load::<FolderPage>(conn)
    .map_err(|e| FlowyError::internal().with_context(format!("Failed to get children: {}", e)))?;

  let mut children_views = Vec::with_capacity(children_pages.len());

  for child_page in children_pages {
    let child_id = child_page.id.clone();
    let mut child_view: FolderView = child_page.into();

    // Calculate the new depth for child nodes
    let next_depth = depth.map(|d| d - 1);

    // Only get grandchildren if we haven't reached the depth limit
    child_view.children = get_page_children_by_id(conn, &child_id, next_depth)?;
    children_views.push(child_view);
  }

  Ok(children_views)
}
