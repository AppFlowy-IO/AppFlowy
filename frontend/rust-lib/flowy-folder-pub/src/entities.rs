use crate::folder_builder::ParentChildViews;
use std::collections::HashMap;

pub enum ImportData {
  AppFlowyDataFolder { items: Vec<AppFlowyData> },
}

pub enum AppFlowyData {
  Folder {
    views: Vec<ParentChildViews>,
    /// Used to update the [DatabaseViewTrackerList] when importing the database.
    database_view_ids_by_database_id: HashMap<String, Vec<String>>,
  },
  CollabObject {
    row_object_ids: Vec<String>,
    document_object_ids: Vec<String>,
    database_object_ids: Vec<String>,
  },
}

pub struct ImportViews {
  pub views: Vec<ParentChildViews>,
  /// Used to update the [DatabaseViewTrackerList] when importing the database.
  pub database_view_ids_by_database_id: HashMap<String, Vec<String>>,
}

pub struct SearchData {
  /// The type of data that is stored in the search index row.
  pub index_type: String,

  /// The `View` that the row references.
  pub view_id: String,

  /// The ID that corresponds to the type that is stored.
  /// View: view_id
  /// Document: page_id
  pub id: String,

  /// The data that is stored in the search index row.
  pub data: String,
}
