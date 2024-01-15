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
