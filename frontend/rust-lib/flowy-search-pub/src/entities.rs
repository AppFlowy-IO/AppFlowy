use std::sync::Arc;

use collab::core::collab::IndexContentReceiver;
use collab_folder::{folder_diff::FolderViewChange, View, ViewIcon, ViewLayout};
use flowy_error::FlowyError;
use lib_infra::async_trait::async_trait;
use uuid::Uuid;

pub struct IndexableData {
  pub id: String,
  pub data: String,
  pub icon: Option<ViewIcon>,
  pub layout: ViewLayout,
  pub workspace_id: Uuid,
}

impl IndexableData {
  pub fn from_view(view: Arc<View>, workspace_id: Uuid) -> Self {
    IndexableData {
      id: view.id.clone(),
      data: view.name.clone(),
      icon: view.icon.clone(),
      layout: view.layout.clone(),
      workspace_id,
    }
  }
}

#[async_trait]
pub trait IndexManager: Send + Sync {
  async fn set_index_content_receiver(&self, rx: IndexContentReceiver, workspace_id: Uuid);
  async fn add_index(&self, data: IndexableData) -> Result<(), FlowyError>;
  async fn update_index(&self, data: IndexableData) -> Result<(), FlowyError>;
  async fn remove_indices(&self, ids: Vec<String>) -> Result<(), FlowyError>;
  async fn remove_indices_for_workspace(&self, workspace_id: Uuid) -> Result<(), FlowyError>;
  async fn is_indexed(&self) -> bool;
}

#[async_trait]
pub trait FolderIndexManager: IndexManager {
  async fn initialize(&self);

  fn index_all_views(&self, views: Vec<Arc<View>>, workspace_id: Uuid);

  fn index_view_changes(
    &self,
    views: Vec<Arc<View>>,
    changes: Vec<FolderViewChange>,
    workspace_id: Uuid,
  );
}
