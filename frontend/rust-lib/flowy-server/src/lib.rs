use std::sync::Arc;

use collab_plugins::cloud_storage::RemoteCollabStorage;

use flowy_database_deps::cloud::DatabaseCloudService;
use flowy_document_deps::cloud::DocumentCloudService;
use flowy_folder_deps::cloud::FolderCloudService;
use flowy_user_deps::cloud::UserService;

pub mod local_server;
mod request;
mod response;
pub mod self_host;
pub mod supabase;
pub mod util;

pub trait AppFlowyServer: Send + Sync + 'static {
  fn enable_sync(&self, _enable: bool) {}
  fn user_service(&self) -> Arc<dyn UserService>;
  fn folder_service(&self) -> Arc<dyn FolderCloudService>;
  fn database_service(&self) -> Arc<dyn DatabaseCloudService>;
  fn document_service(&self) -> Arc<dyn DocumentCloudService>;
  fn collab_storage(&self) -> Option<Arc<dyn RemoteCollabStorage>>;
}
