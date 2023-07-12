use std::collections::HashMap;
use std::sync::Arc;

use parking_lot::RwLock;
use uuid::Uuid;

use flowy_server::supabase::impls::{SupabaseUserAuthServiceImpl, USER_UUID};
use flowy_server::supabase::{PostgresServer, SupabaseServerServiceImpl};
use flowy_server_config::supabase_config::PostgresConfiguration;
use flowy_user::entities::{SignUpResponse, UpdateUserProfileParams};
use flowy_user::event_map::{UserAuthService, UserCredentials};
use lib_infra::box_any::BoxAny;

use crate::setup_log;

// ‼️‼️‼️ Warning: this test will create a table in the database
#[tokio::test]
async fn user_sign_up_test() {
  if dotenv::from_filename("./.env.test").is_err() {
    return;
  }
  let user_service = user_auth_service_impl();
  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), Uuid::new_v4().to_string());
  let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
  assert!(!user.workspace_id.is_empty());
}

fn user_auth_service_impl() -> SupabaseUserAuthServiceImpl<SupabaseServerServiceImpl> {
  let server = Arc::new(PostgresServer::new(
    PostgresConfiguration::from_env().unwrap(),
  ));
  let weak_server = SupabaseServerServiceImpl(Arc::new(RwLock::new(Some(server))));
  SupabaseUserAuthServiceImpl::new(weak_server)
}

#[tokio::test]
async fn user_sign_up_with_existing_uuid_test() {
  if dotenv::from_filename("./.env.test").is_err() {
    return;
  }
  let user_service = user_auth_service_impl();
  let uuid = Uuid::new_v4();

  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), uuid.to_string());
  let _user: SignUpResponse = user_service
    .sign_up(BoxAny::new(params.clone()))
    .await
    .unwrap();
  let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
  assert!(!user.workspace_id.is_empty());
}

#[tokio::test]
async fn update_user_profile_test() {
  if dotenv::from_filename("./.env.test").is_err() {
    return;
  }
  let user_service = user_auth_service_impl();
  let uuid = Uuid::new_v4();

  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), uuid.to_string());
  let user: SignUpResponse = user_service
    .sign_up(BoxAny::new(params.clone()))
    .await
    .unwrap();

  user_service
    .update_user(
      UserCredentials::from_uid(user.user_id),
      UpdateUserProfileParams {
        id: user.user_id,
        auth_type: Default::default(),
        name: Some("123".to_string()),
        email: Some("123@appflowy.io".to_string()),
        password: None,
        icon_url: None,
        openai_key: None,
      },
    )
    .await
    .unwrap();

  let user_profile = user_service
    .get_user_profile(UserCredentials::from_uid(user.user_id))
    .await
    .unwrap()
    .unwrap();

  assert_eq!(user_profile.name, "123");
}

#[tokio::test]
async fn get_user_profile_test() {
  if dotenv::from_filename("./.env.test").is_err() {
    return;
  }
  setup_log();
  let user_service = user_auth_service_impl();
  let uuid = Uuid::new_v4();

  let mut params = HashMap::new();
  params.insert(USER_UUID.to_string(), uuid.to_string());
  let user: SignUpResponse = user_service
    .sign_up(BoxAny::new(params.clone()))
    .await
    .unwrap();

  let credential = UserCredentials::from_uid(user.user_id);

  user_service
    .get_user_profile(credential.clone())
    .await
    .unwrap()
    .unwrap();
  user_service
    .get_user_profile(credential.clone())
    .await
    .unwrap()
    .unwrap();
  user_service
    .get_user_profile(credential.clone())
    .await
    .unwrap()
    .unwrap();
  user_service
    .get_user_profile(credential.clone())
    .await
    .unwrap()
    .unwrap();
  user_service
    .get_user_profile(credential)
    .await
    .unwrap()
    .unwrap();
}

#[tokio::test]
async fn get_not_exist_user_profile_test() {
  if dotenv::from_filename("./.env.test").is_err() {
    return;
  }
  setup_log();
  let user_service = user_auth_service_impl();
  let result = user_service
    .get_user_profile(UserCredentials::from_uid(i64::MAX))
    .await
    .unwrap();
  // user not found
  assert!(result.is_none());
}
