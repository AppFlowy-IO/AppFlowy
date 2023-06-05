use nanoid::nanoid;
use parking_lot::RwLock;
use std::env::temp_dir;
use std::sync::Arc;

use crate::event_builder::EventBuilder;
use flowy_core::{AppFlowyCore, AppFlowyCoreConfig};
use flowy_folder2::entities::{CreateViewPayloadPB, RepeatedViewIdPB, ViewPB, WorkspaceSettingPB};
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

  pub async fn get_current_workspace(&self) -> WorkspaceSettingPB {
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::GetCurrentWorkspace)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::WorkspaceSettingPB>()
  }

  pub async fn delete_view(&self, view_id: &str) {
    let payload = RepeatedViewIdPB {
      items: vec![view_id.to_string()],
    };

    // delete the view. the view will be moved to trash
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::DeleteView)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn create_view(&self, parent_id: &str, name: String) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: Default::default(),
      initial_data: vec![],
      meta: Default::default(),
      set_as_current: false,
    };
    EventBuilder::new(self.clone())
      .event(flowy_folder2::event_map::FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<flowy_folder2::entities::ViewPB>()
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
