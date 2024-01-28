use crate::util::event_builder::EventBuilder;
use af_user::entities::*;
use af_user::event_map::UserWasmEvent::*;
use af_wasm::core::AppFlowyWASMCore;
use flowy_error::FlowyResult;
use flowy_server::af_cloud::define::{USER_DEVICE_ID, USER_SIGN_IN_URL};
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use parking_lot::Once;
use std::collections::HashMap;
use std::sync::Arc;
use uuid::Uuid;

pub struct WASMEventTester {
  core: Arc<AppFlowyWASMCore>,
}

impl WASMEventTester {
  pub async fn new() -> Self {
    setup_log();
    // let config = AFCloudConfiguration {
    //   base_url: "http://localhost".to_string(),
    //   ws_base_url: "ws://localhost/ws".to_string(),
    //   gotrue_url: "http://localhost/gotrue".to_string(),
    // };
    let config = AFCloudConfiguration {
      base_url: "http://localhost:8000".to_string(),
      ws_base_url: "ws://localhost:8000/ws".to_string(),
      gotrue_url: "http://localhost:9999".to_string(),
    };
    let core = Arc::new(AppFlowyWASMCore::new("device_id", config).await.unwrap());
    Self { core }
  }

  pub async fn sign_in_with_email(&self, email: &str) -> FlowyResult<UserProfilePB> {
    let email = unique_email();
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
    EventBuilder::new(self.core.clone())
      .event(SignInPassword)
      .payload(payload)
      .async_send()
      .await;

    // let mut map = HashMap::new();
    // map.insert(USER_SIGN_IN_URL.to_string(), sign_in_url);
    // map.insert(USER_DEVICE_ID.to_string(), uuid::Uuid::new_v4().to_string());
    // let payload = OauthSignInPB {
    //   map,
    //   authenticator: AuthenticatorPB::AppFlowyCloud,
    // };
    //
    // let user_profile = EventBuilder::new(self.core.clone())
    //   .event(OauthSignIn)
    //   .payload(payload)
    //   .async_send()
    //   .await
    //   .try_parse::<UserProfilePB>()?;

    Ok(UserProfilePB {
      id: 0,
      email: "".to_string(),
      name: "".to_string(),
      token: "".to_string(),
      icon_url: "".to_string(),
      openai_key: "".to_string(),
      authenticator: Default::default(),
      encryption_sign: "".to_string(),
      workspace_id: "".to_string(),
      stability_ai_key: "".to_string(),
    })
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
