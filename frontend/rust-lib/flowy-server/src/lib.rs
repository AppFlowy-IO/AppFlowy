use std::sync::Arc;

use collab_plugins::cloud_storage::{CollabObject, RemoteCollabStorage};
use parking_lot::RwLock;

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

pub trait AppFlowyEncryption: Send + Sync + 'static {
  fn get_secret(&self) -> Option<String>;
  fn set_secret(&self, secret: String);
}

impl<T> AppFlowyEncryption for Arc<T>
where
  T: AppFlowyEncryption,
{
  fn get_secret(&self) -> Option<String> {
    (**self).get_secret()
  }

  fn set_secret(&self, secret: String) {
    (**self).set_secret(secret)
  }
}

pub trait AppFlowyServer: Send + Sync + 'static {
  fn set_enable_sync(&self, _enable: bool) {}
  fn set_sync_device_id(&self, _device_id: &str) {}
  fn user_service(&self) -> Arc<dyn UserService>;
  fn folder_service(&self) -> Arc<dyn FolderCloudService>;
  fn database_service(&self) -> Arc<dyn DatabaseCloudService>;
  fn document_service(&self) -> Arc<dyn DocumentCloudService>;
  fn collab_storage(&self, collab_object: &CollabObject) -> Option<Arc<dyn RemoteCollabStorage>>;
}

pub struct EncryptionImpl {
  secret: RwLock<Option<String>>,
}

impl EncryptionImpl {
  pub fn new(secret: Option<String>) -> Self {
    Self {
      secret: RwLock::new(secret),
    }
  }
}

impl AppFlowyEncryption for EncryptionImpl {
  fn get_secret(&self) -> Option<String> {
    self.secret.read().clone()
  }

  fn set_secret(&self, secret: String) {
    *self.secret.write() = Some(secret);
  }
}
