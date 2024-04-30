use std::any::Any;
use std::sync::Arc;

use collab::core::collab::IndexContentReceiver;
use collab_folder::{View, ViewIcon, ViewLayout};
use flowy_error::FlowyError;

pub struct IndexableData {
  pub id: String,
  pub data: String,
  pub icon: Option<ViewIcon>,
  pub layout: ViewLayout,
  pub workspace_id: String,
}

pub trait IndexManager: Send + Sync {
  fn set_index_content_receiver(&self, rx: IndexContentReceiver, workspace_id: String);
  fn add_index(&self, data: IndexableData) -> Result<(), FlowyError>;
  fn update_index(&self, data: IndexableData) -> Result<(), FlowyError>;
  fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError>;
  fn is_indexed(&self) -> bool;

  fn as_any(&self) -> &dyn Any;
}

pub trait FolderIndexManager: IndexManager {
  fn index_all_views(&self, views: Vec<Arc<View>>, workspace_id: String);
}
