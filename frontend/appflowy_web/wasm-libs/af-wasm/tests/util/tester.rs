use crate::util::event_builder::EventBuilder;
use af_user::entities::*;
use af_user::event_map::UserWasmEvent::*;
use af_wasm::core::AppFlowyWASMCore;
use flowy_error::FlowyResult;

use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use parking_lot::Once;

use flowy_document::deps::DocumentData;
use flowy_document::entities::{CreateDocumentPayloadPB, DocumentDataPB, OpenDocumentPayloadPB};
use flowy_document::event_map::DocumentEvent;
use flowy_folder::entities::{CreateViewPayloadPB, ViewLayoutPB, ViewPB};
use flowy_folder::event_map::FolderEvent;
use std::sync::Arc;
use uuid::Uuid;

pub struct WASMEventTester {
  core: Arc<AppFlowyWASMCore>,
}

impl WASMEventTester {
  pub async fn new() -> Self {
    setup_log();
    let config = AFCloudConfiguration {
      base_url: "http://localhost".to_string(),
      ws_base_url: "ws://localhost/ws/v1".to_string(),
      gotrue_url: "http://localhost/gotrue".to_string(),
    };
    let core = Arc::new(AppFlowyWASMCore::new("device_id", config).await.unwrap());
    Self { core }
  }

  pub async fn sign_in_with_email(&self, email: &str) -> FlowyResult<UserProfilePB> {
    let email = email.to_string();
    let password = "AppFlowy!2024".to_string();
    let payload = AddUserPB {
      email: email.clone(),
      password: password.clone(),
    };
    EventBuilder::new(self.core.clone())
      .event(AddUser)
      .payload(payload)
      .async_send()
      .await;

    let payload = UserSignInPB { email, password };
    let user_profile = EventBuilder::new(self.core.clone())
      .event(SignInPassword)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserProfilePB>();
    Ok(user_profile)
  }

  pub async fn create_and_open_document(&self, parent_id: &str) -> ViewPB {
    let payload = CreateViewPayloadPB {
      parent_view_id: parent_id.to_string(),
      name,
      desc: "".to_string(),
      thumbnail: None,
      layout: ViewLayoutPB::Document,
      initial_data,
      meta: Default::default(),
      set_as_current: true,
      index: None,
    };
    let view = self
      .event_builder()
      .event(FolderEvent::CreateView)
      .payload(payload)
      .async_send()
      .await
      .parse::<ViewPB>();

    let payload = OpenDocumentPayloadPB {
      document_id: view.id.clone(),
    };

    let _ = self
      .event_builder()
      .event(DocumentEvent::OpenDocument)
      .payload(payload)
      .async_send()
      .await
      .parse::<DocumentDataPB>();
    view
  }

  fn event_builder(&self) -> EventBuilder {
    EventBuilder::new(self.core.clone())
  }
}

pub fn unique_email() -> String {
  format!("{}@appflowy.io", Uuid::new_v4())
}

pub fn setup_log() {
  static START: Once = Once::new();
  START.call_once(|| {
    tracing_wasm::set_as_global_default();
  });
}
