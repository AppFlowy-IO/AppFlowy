use std::collections::HashMap;
use std::convert::TryFrom;
use std::sync::Arc;

use bytes::Bytes;

use flowy_folder::entities::{RepeatedViewPB, WorkspacePB};
use nanoid::nanoid;
use protobuf::ProtobufError;
use tokio::sync::broadcast::{channel, Sender};
use tracing::error;
use uuid::Uuid;

use flowy_folder::event_map::FolderEvent;
use flowy_notification::entities::SubscribeObject;
use flowy_notification::NotificationSender;
use flowy_server::af_cloud::define::{USER_DEVICE_ID, USER_EMAIL, USER_SIGN_IN_URL, USER_UUID};
use flowy_server_pub::af_cloud_config::AFCloudConfiguration;
use flowy_server_pub::AuthenticatorType;
use flowy_user::entities::{
  AuthenticatorPB, ChangeWorkspaceIconPB, CloudSettingPB, CreateWorkspacePB, ImportAppFlowyDataPB,
  OauthSignInPB, RenameWorkspacePB, RepeatedUserWorkspacePB, SignInUrlPB, SignInUrlPayloadPB,
  SignUpPayloadPB, UpdateCloudConfigPB, UpdateUserProfilePayloadPB, UserProfilePB,
  UserWorkspaceIdPB, UserWorkspacePB,
};
use flowy_user::errors::{FlowyError, FlowyResult};
use flowy_user::event_map::UserEvent;
use lib_dispatch::prelude::{af_spawn, AFPluginDispatcher, AFPluginRequest, ToBytes};

use crate::event_builder::EventBuilder;
use crate::EventIntegrationTest;

impl EventIntegrationTest {
  pub async fn enable_encryption(&self) -> String {
    let config = EventBuilder::new(self.clone())
      .event(UserEvent::GetCloudConfig)
      .async_send()
      .await
      .parse::<CloudSettingPB>();
    let update = UpdateCloudConfigPB {
      enable_sync: None,
      enable_encrypt: Some(true),
    };
    let error = EventBuilder::new(self.clone())
      .event(UserEvent::SetCloudConfig)
      .payload(update)
      .async_send()
      .await
      .error();
    assert!(error.is_none());
    config.encrypt_secret
  }

  /// Create a anonymous user for given test.
  pub async fn new_anon() -> Self {
    let test = Self::new().await;
    test.sign_up_as_anon().await;
    test
  }

  pub async fn sign_up_as_anon(&self) -> SignUpContext {
    let password = login_password();
    let email = unique_email();
    let payload = SignUpPayloadPB {
      email,
      name: "appflowy".to_string(),
      password: password.clone(),
      auth_type: AuthenticatorPB::Local,
      device_id: uuid::Uuid::new_v4().to_string(),
    }
    .into_bytes()
    .unwrap();

    let request = AFPluginRequest::new(UserEvent::SignUp).payload(payload);
    let user_profile = AFPluginDispatcher::async_send(&self.appflowy_core.dispatcher(), request)
      .await
      .parse::<UserProfilePB, FlowyError>()
      .unwrap()
      .unwrap();

    // let _ = create_default_workspace_if_need(dispatch.clone(), &user_profile.id);
    SignUpContext {
      user_profile,
      password,
    }
  }

  pub async fn af_cloud_sign_up(&self) -> UserProfilePB {
    let email = unique_email();
    self.af_cloud_sign_in_with_email(&email).await.unwrap()
  }

  pub async fn supabase_party_sign_up(&self) -> UserProfilePB {
    let map = third_party_sign_up_param(Uuid::new_v4().to_string());
    let payload = OauthSignInPB {
      map,
      authenticator: AuthenticatorPB::Supabase,
    };

    EventBuilder::new(self.clone())
      .event(UserEvent::OauthSignIn)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserProfilePB>()
  }

  pub async fn sign_out(&self) {
    EventBuilder::new(self.clone())
      .event(UserEvent::SignOut)
      .async_send()
      .await;
  }

  pub fn set_auth_type(&self, auth_type: AuthenticatorPB) {
    *self.authenticator.write() = auth_type;
  }

  pub async fn init_anon_user(&self) -> UserProfilePB {
    self.sign_up_as_anon().await.user_profile
  }

  pub async fn get_user_profile(&self) -> Result<UserProfilePB, FlowyError> {
    EventBuilder::new(self.clone())
      .event(UserEvent::GetUserProfile)
      .async_send()
      .await
      .try_parse::<UserProfilePB>()
  }

  pub async fn update_user_profile(&self, params: UpdateUserProfilePayloadPB) {
    EventBuilder::new(self.clone())
      .event(UserEvent::UpdateUserProfile)
      .payload(params)
      .async_send()
      .await;
  }

  pub async fn af_cloud_sign_in_with_email(&self, email: &str) -> FlowyResult<UserProfilePB> {
    let payload = SignInUrlPayloadPB {
      email: email.to_string(),
      authenticator: AuthenticatorPB::AppFlowyCloud,
    };
    let sign_in_url = EventBuilder::new(self.clone())
      .event(UserEvent::GenerateSignInURL)
      .payload(payload)
      .async_send()
      .await
      .try_parse::<SignInUrlPB>()?
      .sign_in_url;

    let mut map = HashMap::new();
    map.insert(USER_SIGN_IN_URL.to_string(), sign_in_url);
    map.insert(USER_DEVICE_ID.to_string(), Uuid::new_v4().to_string());
    let payload = OauthSignInPB {
      map,
      authenticator: AuthenticatorPB::AppFlowyCloud,
    };

    let user_profile = EventBuilder::new(self.clone())
      .event(UserEvent::OauthSignIn)
      .payload(payload)
      .async_send()
      .await
      .try_parse::<UserProfilePB>()?;

    Ok(user_profile)
  }

  pub async fn supabase_sign_up_with_uuid(
    &self,
    uuid: &str,
    email: Option<String>,
  ) -> FlowyResult<UserProfilePB> {
    let mut map = HashMap::new();
    map.insert(USER_UUID.to_string(), uuid.to_string());
    map.insert(USER_DEVICE_ID.to_string(), uuid.to_string());
    map.insert(
      USER_EMAIL.to_string(),
      email.unwrap_or_else(|| format!("{}@appflowy.io", nanoid!(10))),
    );
    let payload = OauthSignInPB {
      map,
      authenticator: AuthenticatorPB::Supabase,
    };

    let user_profile = EventBuilder::new(self.clone())
      .event(UserEvent::OauthSignIn)
      .payload(payload)
      .async_send()
      .await
      .try_parse::<UserProfilePB>()?;

    Ok(user_profile)
  }

  pub async fn import_appflowy_data(
    &self,
    path: String,
    name: Option<String>,
  ) -> Result<(), FlowyError> {
    let payload = ImportAppFlowyDataPB {
      path,
      import_container_name: name,
    };
    match EventBuilder::new(self.clone())
      .event(UserEvent::ImportAppFlowyDataFolder)
      .payload(payload)
      .async_send()
      .await
      .error()
    {
      Some(err) => Err(err),
      None => Ok(()),
    }
  }

  pub async fn create_workspace(&self, name: &str) -> UserWorkspacePB {
    let payload = CreateWorkspacePB {
      name: name.to_string(),
    };
    EventBuilder::new(self.clone())
      .event(UserEvent::CreateWorkspace)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserWorkspacePB>()
  }

  pub async fn rename_workspace(
    &self,
    workspace_id: &str,
    new_name: &str,
  ) -> Result<(), FlowyError> {
    let payload = RenameWorkspacePB {
      workspace_id: workspace_id.to_owned(),
      new_name: new_name.to_owned(),
    };
    match EventBuilder::new(self.clone())
      .event(UserEvent::RenameWorkspace)
      .payload(payload)
      .async_send()
      .await
      .error()
    {
      Some(err) => Err(err),
      None => Ok(()),
    }
  }

  pub async fn change_workspace_icon(
    &self,
    workspace_id: &str,
    new_icon: &str,
  ) -> Result<(), FlowyError> {
    let payload = ChangeWorkspaceIconPB {
      workspace_id: workspace_id.to_owned(),
      new_icon: new_icon.to_owned(),
    };
    match EventBuilder::new(self.clone())
      .event(UserEvent::ChangeWorkspaceIcon)
      .payload(payload)
      .async_send()
      .await
      .error()
    {
      Some(err) => Err(err),
      None => Ok(()),
    }
  }

  pub async fn folder_read_current_workspace(&self) -> WorkspacePB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadCurrentWorkspace)
      .async_send()
      .await
      .parse()
  }

  pub async fn folder_read_current_workspace_views(&self) -> RepeatedViewPB {
    EventBuilder::new(self.clone())
      .event(FolderEvent::ReadCurrentWorkspaceViews)
      .async_send()
      .await
      .parse()
  }

  pub async fn get_all_workspaces(&self) -> RepeatedUserWorkspacePB {
    EventBuilder::new(self.clone())
      .event(UserEvent::GetAllWorkspace)
      .async_send()
      .await
      .parse::<RepeatedUserWorkspacePB>()
  }

  pub async fn delete_workspace(&self, workspace_id: &str) {
    let payload = UserWorkspaceIdPB {
      workspace_id: workspace_id.to_string(),
    };
    EventBuilder::new(self.clone())
      .event(UserEvent::DeleteWorkspace)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn open_workspace(&self, workspace_id: &str) {
    let payload = UserWorkspaceIdPB {
      workspace_id: workspace_id.to_string(),
    };
    EventBuilder::new(self.clone())
      .event(UserEvent::OpenWorkspace)
      .payload(payload)
      .async_send()
      .await;
  }

  pub async fn leave_workspace(&self, workspace_id: &str) {
    let payload = UserWorkspaceIdPB {
      workspace_id: workspace_id.to_string(),
    };
    EventBuilder::new(self.clone())
      .event(UserEvent::LeaveWorkspace)
      .payload(payload)
      .async_send()
      .await;
  }
}

#[derive(Clone)]
pub struct TestNotificationSender {
  sender: Arc<Sender<SubscribeObject>>,
}

impl Default for TestNotificationSender {
  fn default() -> Self {
    let (sender, _) = channel(1000);
    Self {
      sender: Arc::new(sender),
    }
  }
}

impl TestNotificationSender {
  pub fn new() -> Self {
    Self::default()
  }

  pub fn subscribe<T>(&self, id: &str, ty: impl Into<i32> + Send) -> tokio::sync::mpsc::Receiver<T>
  where
    T: TryFrom<Bytes, Error = ProtobufError> + Send + 'static,
  {
    let id = id.to_string();
    let (tx, rx) = tokio::sync::mpsc::channel::<T>(10);
    let mut receiver = self.sender.subscribe();
    let ty = ty.into();
    af_spawn(async move {
      // DatabaseNotification::DidUpdateDatabaseSnapshotState
      while let Ok(value) = receiver.recv().await {
        if value.id == id && value.ty == ty {
          if let Some(payload) = value.payload {
            match T::try_from(Bytes::from(payload)) {
              Ok(object) => {
                let _ = tx.send(object).await;
              },
              Err(e) => {
                panic!(
                  "Failed to parse notification payload to type: {:?} with error: {}",
                  std::any::type_name::<T>(),
                  e
                );
              },
            }
          }
        }
      }
    });
    rx
  }

  pub fn subscribe_with_condition<T, F>(&self, id: &str, when: F) -> tokio::sync::mpsc::Receiver<T>
  where
    T: TryFrom<Bytes, Error = ProtobufError> + Send + 'static,
    F: Fn(&T) -> bool + Send + 'static,
  {
    let id = id.to_string();
    let (tx, rx) = tokio::sync::mpsc::channel::<T>(1);
    let mut receiver = self.sender.subscribe();
    af_spawn(async move {
      while let Ok(value) = receiver.recv().await {
        if value.id == id {
          if let Some(payload) = value.payload {
            if let Ok(object) = T::try_from(Bytes::from(payload)) {
              if when(&object) {
                let _ = tx.send(object).await;
              }
            }
          }
        }
      }
    });
    rx
  }
}
impl NotificationSender for TestNotificationSender {
  fn send_subject(&self, subject: SubscribeObject) -> Result<(), String> {
    if let Err(err) = self.sender.send(subject) {
      error!("Failed to send notification: {:?}", err);
    }
    Ok(())
  }
}

pub fn third_party_sign_up_param(uuid: String) -> HashMap<String, String> {
  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), uuid);
  params.insert(
    USER_EMAIL.to_string(),
    format!("{}@test.com", Uuid::new_v4()),
  );
  params.insert(USER_DEVICE_ID.to_string(), Uuid::new_v4().to_string());
  params
}

pub fn unique_email() -> String {
  format!("{}@appflowy.io", Uuid::new_v4())
}

pub fn login_email() -> String {
  "annie2@appflowy.io".to_string()
}

pub fn login_password() -> String {
  "HelloWorld!123".to_string()
}
pub struct SignUpContext {
  pub user_profile: UserProfilePB,
  pub password: String,
}

pub async fn user_localhost_af_cloud() {
  AuthenticatorType::AppFlowyCloud.write_env();
  let base_url =
    std::env::var("af_cloud_test_base_url").unwrap_or("http://localhost:8000".to_string());
  let ws_base_url =
    std::env::var("af_cloud_test_ws_url").unwrap_or("ws://localhost:8000/ws/v1".to_string());
  let gotrue_url =
    std::env::var("af_cloud_test_gotrue_url").unwrap_or("http://localhost:9999".to_string());
  AFCloudConfiguration {
    base_url,
    ws_base_url,
    gotrue_url,
  }
  .write_env();
  std::env::set_var("GOTRUE_ADMIN_EMAIL", "admin@example.com");
  std::env::set_var("GOTRUE_ADMIN_PASSWORD", "password");
}

#[allow(dead_code)]
pub async fn user_localhost_af_cloud_with_nginx() {
  std::env::set_var("af_cloud_test_base_url", "http://localhost");
  std::env::set_var("af_cloud_test_ws_url", "ws://localhost/ws/v1");
  std::env::set_var("af_cloud_test_gotrue_url", "http://localhost/gotrue");
  user_localhost_af_cloud().await
}
