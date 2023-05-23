use flowy_user::entities::{AuthTypePB, SignInPayloadPB, SignUpPayloadPB, UserProfilePB};
use flowy_user::errors::FlowyError;
use flowy_user::event_map::UserEvent::*;
use lib_dispatch::prelude::{AFPluginDispatcher, AFPluginRequest, ToBytes};
use nanoid::nanoid;
use std::sync::Arc;

pub fn random_email() -> String {
  format!("{}@appflowy.io", nanoid!(20))
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

pub fn sign_up(dispatch: Arc<AFPluginDispatcher>) -> SignUpContext {
  let password = login_password();
  let payload = SignUpPayloadPB {
    email: random_email(),
    name: "app flowy".to_string(),
    password: password.clone(),
    auth_type: AuthTypePB::Local,
  }
  .into_bytes()
  .unwrap();

  let request = AFPluginRequest::new(SignUp).payload(payload);
  let user_profile = AFPluginDispatcher::sync_send(dispatch, request)
    .parse::<UserProfilePB, FlowyError>()
    .unwrap()
    .unwrap();

  SignUpContext {
    user_profile,
    password,
  }
}

pub async fn async_sign_up(
  dispatch: Arc<AFPluginDispatcher>,
  auth_type: AuthTypePB,
) -> SignUpContext {
  let password = login_password();
  let email = random_email();
  let payload = SignUpPayloadPB {
    email,
    name: "app flowy".to_string(),
    password: password.clone(),
    auth_type,
  }
  .into_bytes()
  .unwrap();

  let request = AFPluginRequest::new(SignUp).payload(payload);
  let user_profile = AFPluginDispatcher::async_send(dispatch.clone(), request)
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

pub async fn init_user_setting(dispatch: Arc<AFPluginDispatcher>) {
  let request = AFPluginRequest::new(InitUser);
  let _ = AFPluginDispatcher::async_send(dispatch.clone(), request).await;
}

#[allow(dead_code)]
fn sign_in(dispatch: Arc<AFPluginDispatcher>) -> UserProfilePB {
  let payload = SignInPayloadPB {
    email: login_email(),
    password: login_password(),
    name: "rust".to_owned(),
    auth_type: AuthTypePB::Local,
  }
  .into_bytes()
  .unwrap();

  let request = AFPluginRequest::new(SignIn).payload(payload);
  AFPluginDispatcher::sync_send(dispatch, request)
    .parse::<UserProfilePB, FlowyError>()
    .unwrap()
    .unwrap()
}

#[allow(dead_code)]
fn logout(dispatch: Arc<AFPluginDispatcher>) {
  let _ = AFPluginDispatcher::sync_send(dispatch, AFPluginRequest::new(SignOut));
}
