use crate::folder_builder::ParentChildViews;
use collab_folder::{ViewIcon, ViewLayout};
use serde::{Deserialize, Serialize};
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

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct PublishDatabaseData {
  /// The encoded collab data for the database itself
  pub database_collab: Vec<u8>,

  /// The encoded collab data for the database rows
  /// Use the row_id as the key
  pub database_row_collabs: HashMap<String, Vec<u8>>,

  /// The encoded collab data for the documents inside the database rows
  /// It's not used for now
  pub database_row_document_collabs: HashMap<String, Vec<u8>>,

  /// Visible view ids
  pub visible_database_view_ids: Vec<String>,

  /// Relation view id map
  /// It's not used for now
  pub database_view_relations: HashMap<String, String>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PublishDocumentPayload {
  pub meta: PublishViewMeta,

  /// The encoded collab data for the document
  pub data: Vec<u8>,
}

#[derive(Clone, Debug)]
pub struct PublishDatabasePayload {
  pub meta: PublishViewMeta,
  pub data: PublishDatabaseData,
}

#[derive(Clone, Debug)]
pub enum PublishPayload {
  Document(PublishDocumentPayload),
  Database(PublishDatabasePayload),
  Unknown,
}

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PublishInfoResponse {
  pub view_id: String,
  /// One part of publish url: /{namespace}/{publish_name}
  pub namespace: Option<String>,
  pub publish_name: String,
}
