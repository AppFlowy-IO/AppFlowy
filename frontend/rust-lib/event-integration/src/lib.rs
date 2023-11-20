use std::env::temp_dir;
use std::path::PathBuf;
use std::sync::Arc;

use nanoid::nanoid;
use parking_lot::RwLock;

use flowy_core::config::AppFlowyCoreConfig;
use flowy_core::AppFlowyCore;
use flowy_notification::register_notification_sender;
use flowy_user::entities::AuthTypePB;

use crate::user_event::TestNotificationSender;

pub mod database_event;
pub mod document;
pub mod document_event;
pub mod event_builder;
pub mod folder_event;
pub mod user_event;

#[derive(Clone)]
pub struct EventIntegrationTest {
  pub auth_type: Arc<RwLock<AuthTypePB>>,
  pub inner: AppFlowyCore,
  #[allow(dead_code)]
  cleaner: Arc<Cleaner>,
  pub notification_sender: TestNotificationSender,
}

impl EventIntegrationTest {
  pub async fn new() -> Self {
    let temp_dir = temp_dir().join(nanoid!(6));
    std::fs::create_dir_all(&temp_dir).unwrap();
    Self::new_with_user_data_path(temp_dir, nanoid!(6)).await
  }
  pub async fn new_with_user_data_path(path_buf: PathBuf, name: String) -> Self {
    let path = path_buf.to_str().unwrap().to_string();
    let device_id = uuid::Uuid::new_v4().to_string();
    let config = AppFlowyCoreConfig::new(path.clone(), path, device_id, name).log_filter(
      "trace",
      vec![
        "flowy_test".to_string(),
        "tokio".to_string(),
        "lib_dispatch".to_string(),
      ],
    );

    let inner = init_core(config).await;
    let notification_sender = TestNotificationSender::new();
    let auth_type = Arc::new(RwLock::new(AuthTypePB::Local));
    register_notification_sender(notification_sender.clone());
    std::mem::forget(inner.dispatcher());
    Self {
      inner,
      auth_type,
      notification_sender,
      cleaner: Arc::new(Cleaner(path_buf)),
    }
  }
}

#[cfg(feature = "single_thread")]
async fn init_core(config: AppFlowyCoreConfig) -> AppFlowyCore {
  // let runtime = tokio::runtime::Runtime::new().unwrap();
  // let local_set = tokio::task::LocalSet::new();
  // runtime.block_on(AppFlowyCore::new(config))
  AppFlowyCore::new(config).await
}

#[cfg(not(feature = "single_thread"))]
async fn init_core(config: AppFlowyCoreConfig) -> AppFlowyCore {
  std::thread::spawn(|| AppFlowyCore::new(config))
    .join()
    .unwrap()
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
