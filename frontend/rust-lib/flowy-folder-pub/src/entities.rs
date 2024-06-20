use crate::folder_builder::ParentChildViews;
use collab_folder::{ViewIcon, ViewLayout};
use serde::Serialize;
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

#[derive(Serialize, Clone, Debug, Eq, PartialEq)]
pub struct PublishViewInfo {
  pub view_id: String,
  pub name: String,
  pub icon: Option<ViewIcon>,
  pub layout: ViewLayout,
  pub extra: Option<String>,
  pub created_by: Option<i64>,
  pub last_edited_by: Option<i64>,
  pub last_edited_time: i64,
  pub created_at: i64,
  pub child_views: Option<Vec<PublishViewInfo>>,
}

#[derive(Serialize, Clone, Debug, Eq, PartialEq)]
pub struct PublishViewMetaData {
  pub view: PublishViewInfo,
  pub child_views: Vec<PublishViewInfo>,
  pub ancestor_views: Vec<PublishViewInfo>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PublishViewMeta {
  pub metadata: PublishViewMetaData,
  pub view_id: String,
  pub publish_name: String,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PublishViewPayload {
  pub meta: PublishViewMeta,
  pub data: Vec<u8>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PublishInfoResponse {
  pub view_id: String,
  pub publish_name: String,
  pub namespace: Option<String>,
}
