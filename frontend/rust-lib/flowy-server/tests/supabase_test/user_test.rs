use uuid::Uuid;

use flowy_encrypt::{encrypt_text, generate_encryption_secret};
use flowy_error::FlowyError;
use flowy_user_pub::entities::*;
use lib_infra::box_any::BoxAny;

use crate::supabase_test::util::{
  get_supabase_ci_config, third_party_sign_up_param, user_auth_service,
};

// ‼️‼️‼️ Warning: this test will create a table in the database
#[tokio::test]
async fn supabase_user_sign_up_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: AuthResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
  assert!(!user.latest_workspace.id.is_empty());
  assert!(!user.user_workspaces.is_empty());
  assert!(!user.latest_workspace.database_indexer_id.is_empty());
}

#[tokio::test]
async fn supabase_user_sign_up_with_existing_uuid_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let _user: AuthResponse = user_service
    .sign_up(BoxAny::new(params.clone()))
    .await
    .unwrap();
  let user: AuthResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
  assert!(!user.latest_workspace.id.is_empty());
  assert!(!user.latest_workspace.database_indexer_id.is_empty());
  assert!(!user.user_workspaces.is_empty());
}

#[tokio::test]
async fn supabase_update_user_profile_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: AuthResponse = user_service
    .sign_up(BoxAny::new(params.clone()))
    .await
    .unwrap();

  let params = UpdateUserProfileParams::new(user.user_id)
    .with_name("123")
    .with_email(format!("{}@test.com", Uuid::new_v4()));

  user_service
    .update_user(UserCredentials::from_uid(user.user_id), params)
    .await
    .unwrap();

  let user_profile = user_service
    .get_user_profile(UserCredentials::from_uid(user.user_id))
    .await
    .unwrap();

  assert_eq!(user_profile.name, "123");
}

#[tokio::test]
async fn supabase_get_user_profile_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: AuthResponse = user_service
    .sign_up(BoxAny::new(params.clone()))
    .await
    .unwrap();

  let credential = UserCredentials::from_uid(user.user_id);
  user_service
    .get_user_profile(credential.clone())
    .await
    .unwrap();
}

#[tokio::test]
async fn supabase_get_not_exist_user_profile_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }

  let user_service = user_auth_service();
  let result: FlowyError = user_service
    .get_user_profile(UserCredentials::from_uid(i64::MAX))
    .await
    .unwrap_err();
  // user not found
  assert!(result.is_record_not_found());
}

#[tokio::test]
async fn user_encryption_sign_test() {
  if get_supabase_ci_config().is_none() {
    return;
  }
  let user_service = user_auth_service();
  let uuid = Uuid::new_v4().to_string();
  let params = third_party_sign_up_param(uuid);
  let user: AuthResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();

  // generate encryption sign
  let secret = generate_encryption_secret();
  let sign = encrypt_text(user.user_id.to_string(), &secret).unwrap();

  user_service
    .update_user(
      UserCredentials::from_uid(user.user_id),
      UpdateUserProfileParams::new(user.user_id)
        .with_encryption_type(EncryptionType::SelfEncryption(sign.clone())),
    )
    .await
    .unwrap();

  let user_profile: UserProfile = user_service
    .get_user_profile(UserCredentials::from_uid(user.user_id))
    .await
    .unwrap();
  assert_eq!(
    user_profile.encryption_type,
    EncryptionType::SelfEncryption(sign)
  );
}
