use flowy_folder2::deps::FolderCloudService;
use std::sync::Arc;

use flowy_user::event_map::UserAuthService;

pub mod local_server;
mod request;
mod response;
pub mod self_host;
pub mod supabase;

pub trait AppFlowyServer: Send + Sync + 'static {
  fn user_service(&self) -> Arc<dyn UserAuthService>;
  fn folder_service(&self) -> Arc<dyn FolderCloudService>;
}
