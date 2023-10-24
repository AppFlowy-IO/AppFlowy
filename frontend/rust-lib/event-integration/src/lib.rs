use std::env::temp_dir;
use std::path::PathBuf;
use std::sync::Arc;

use nanoid::nanoid;
use parking_lot::RwLock;

use flowy_core::{AppFlowyCore, AppFlowyCoreConfig};
use flowy_notification::register_notification_sender;
use flowy_user::entities::AuthTypePB;

use crate::test_user::TestNotificationSender;

pub mod document;
pub mod event_builder;
pub mod test_database;
pub mod test_document;
pub mod test_folder;
pub mod test_user;

#[derive(Clone)]
pub struct EventIntegrationTest {
  pub auth_type: Arc<RwLock<AuthTypePB>>,
  pub inner: AppFlowyCore,
  #[allow(dead_code)]
  cleaner: Arc<Cleaner>,
  pub notification_sender: TestNotificationSender,
}

impl Default for EventIntegrationTest {
  fn default() -> Self {
    let temp_dir = temp_dir().join(nanoid!(6));
    std::fs::create_dir_all(&temp_dir).unwrap();
    Self::new_with_user_data_path(temp_dir, nanoid!(6))
  }
}

impl EventIntegrationTest {
  pub fn new() -> Self {
    Self::default()
  }
  pub fn new_with_user_data_path(path: PathBuf, name: String) -> Self {
    let config = AppFlowyCoreConfig::new(path.to_str().unwrap(), name).log_filter(
      "trace",
      vec![
        "flowy_test".to_string(),
        // "lib_dispatch".to_string()
      ],
    );

    let inner = std::thread::spawn(|| AppFlowyCore::new(config))
      .join()
      .unwrap();
    let notification_sender = TestNotificationSender::new();
    let auth_type = Arc::new(RwLock::new(AuthTypePB::Local));
    register_notification_sender(notification_sender.clone());
    std::mem::forget(inner.dispatcher());
    Self {
      inner,
      auth_type,
      notification_sender,
      cleaner: Arc::new(Cleaner(path)),
    }
  }
}

impl std::ops::Deref for EventIntegrationTest {
  type Target = AppFlowyCore;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

pub struct Cleaner(PathBuf);

impl Cleaner {
  pub fn new(dir: PathBuf) -> Self {
    Cleaner(dir)
  }

  fn cleanup(dir: &PathBuf) {
    let _ = std::fs::remove_dir_all(dir);
  }
}

impl Drop for Cleaner {
  fn drop(&mut self) {
    Self::cleanup(&self.0)
  }
}
