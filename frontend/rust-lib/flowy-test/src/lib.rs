use nanoid::nanoid;
use parking_lot::RwLock;
use std::env::temp_dir;
use std::sync::Arc;

use flowy_core::{AppFlowyCore, AppFlowyCoreConfig};
use flowy_user::entities::{AuthTypePB, UserProfilePB};

use crate::user_event::{async_sign_up, init_user_setting, SignUpContext};
pub mod event_builder;
pub mod folder_event;
pub mod user_event;

#[derive(Clone)]
pub struct FlowyCoreTest {
  auth_type: Arc<RwLock<AuthTypePB>>,
  inner: AppFlowyCore,
}

impl Default for FlowyCoreTest {
  fn default() -> Self {
    let temp_dir = temp_dir();
    let config =
      AppFlowyCoreConfig::new(temp_dir.to_str().unwrap(), nanoid!(6)).log_filter("info", vec![]);
    let inner = std::thread::spawn(|| AppFlowyCore::new(config))
      .join()
      .unwrap();
    let auth_type = Arc::new(RwLock::new(AuthTypePB::Local));
    std::mem::forget(inner.dispatcher());
    Self { inner, auth_type }
  }
}

impl FlowyCoreTest {
  pub fn new() -> Self {
    Self::default()
  }

  pub async fn new_with_user() -> Self {
    let test = Self::default();
    test.sign_up().await;
    test
  }

  pub async fn sign_up(&self) -> SignUpContext {
    let auth_type = self.auth_type.read().clone();
    async_sign_up(self.inner.dispatcher(), auth_type).await
  }

  pub fn set_auth_type(&self, auth_type: AuthTypePB) {
    *self.auth_type.write() = auth_type;
  }

  pub async fn init_user(&self) -> UserProfilePB {
    let auth_type = self.auth_type.read().clone();
    let context = async_sign_up(self.inner.dispatcher(), auth_type).await;
    init_user_setting(self.inner.dispatcher()).await;
    context.user_profile
  }
}

impl std::ops::Deref for FlowyCoreTest {
  type Target = AppFlowyCore;

  fn deref(&self) -> &Self::Target {
    &self.inner
  }
}

// pub struct TestNotificationSender {
//   pub(crate) sender: tokio::sync::mpsc::Sender<()>,
// }
//
// impl NotificationSender for TestNotificationSender {
//   fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
//     todo!()
//   }
// }
