use crate::manager::{FolderManager, FolderUser};
use crate::view_operation::FolderOperationHandlers;
use collab::lock::RwLock;
use collab_folder::Folder;
use collab_integrate::collab_builder::AppFlowyCollabBuilder;
use flowy_folder_pub::cloud::FolderCloudService;
use flowy_search_pub::entities::FolderIndexManager;
use std::sync::Arc;

impl FolderManager {
  pub fn get_mutex_folder(&self) -> Option<Arc<RwLock<Folder>>> {
    self.mutex_folder.load_full()
  }

  pub fn get_cloud_service(&self) -> Arc<dyn FolderCloudService> {
    self.cloud_service.clone()
  }

  pub fn get_user(&self) -> Arc<dyn FolderUser> {
    self.user.clone()
  }

  pub fn get_indexer(&self) -> Arc<dyn FolderIndexManager> {
    self.folder_indexer.clone()
  }

  pub fn get_collab_builder(&self) -> Arc<AppFlowyCollabBuilder> {
    self.collab_builder.clone()
  }

  pub fn get_operation_handlers(&self) -> FolderOperationHandlers {
    self.operation_handlers.clone()
  }
}
