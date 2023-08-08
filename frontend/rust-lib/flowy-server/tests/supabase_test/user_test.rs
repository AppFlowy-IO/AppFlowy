use uuid::Uuid;

use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;

use crate::supabase_test::util::{get_supabase_config, sign_up_param, user_auth_service};

// ‼️‼️‼️ Warning: this test will create a table in the database
#[tokio::test]
async fn supabase_user_sign_up_test() {
  if get_supabase_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = sign_up_param(uuid);
  let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
  assert!(!user.latest_workspace.id.is_empty());
  assert!(!user.user_workspaces.is_empty());
  assert!(!user.latest_workspace.database_storage_id.is_empty());
}

#[tokio::test]
async fn supabase_user_sign_up_with_existing_uuid_test() {
  if get_supabase_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = sign_up_param(uuid);
  let _user: SignUpResponse = user_service
    .sign_up(BoxAny::new(params.clone()))
    .await
    .unwrap();
  let user: SignUpResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
  assert!(!user.latest_workspace.id.is_empty());
  assert!(!user.latest_workspace.database_storage_id.is_empty());
  assert!(!user.user_workspaces.is_empty());
}

#[tokio::test]
async fn supabase_update_user_profile_test() {
  if get_supabase_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = sign_up_param(uuid);
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
        email: Some(format!("{}@test.com", Uuid::new_v4())),
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
async fn supabase_get_user_profile_test() {
  if get_supabase_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = sign_up_param(uuid);
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
}

#[tokio::test]
async fn supabase_get_not_exist_user_profile_test() {
  if get_supabase_config().is_none() {
    return;
  }

  let user_service = user_auth_service();
  let result = user_service
    .get_user_profile(UserCredentials::from_uid(i64::MAX))
    .await
    .unwrap();
  // user not found
  assert!(result.is_none());
}
