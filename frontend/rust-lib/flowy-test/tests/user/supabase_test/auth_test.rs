use std::collections::HashMap;

use flowy_test::event_builder::EventBuilder;
use flowy_test::FlowyCoreTest;
use flowy_user::entities::{
  AuthTypePB, ThirdPartyAuthPB, UpdateUserProfilePayloadPB, UserProfilePB,
};
use flowy_user::errors::ErrorCode;
use flowy_user::event_map::UserEvent::*;

use crate::util::*;

#[tokio::test]
async fn sign_up_test() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    let mut map = HashMap::new();
    map.insert("uuid".to_string(), uuid::Uuid::new_v4().to_string());
    let payload = ThirdPartyAuthPB {
      map,
      auth_type: AuthTypePB::Supabase,
    };

    let response = EventBuilder::new(test.clone())
      .event(ThirdPartyAuth)
      .payload(payload)
      .async_send()
      .await
      .parse::<UserProfilePB>();
    dbg!(&response);
  }
}

#[tokio::test]
async fn check_not_exist_user_test() {
  if let Some(test) = FlowySupabaseTest::new() {
    let err = test
      .check_user_with_uuid(&uuid::Uuid::new_v4().to_string())
      .await
      .unwrap_err();
    assert_eq!(err.code, ErrorCode::UserNotExist.value());
  }
}

#[tokio::test]
async fn get_user_profile_test() {
  if let Some(test) = FlowySupabaseTest::new() {
    let uuid = uuid::Uuid::new_v4().to_string();
    test.sign_up_with_uuid(&uuid).await;

    let result = test.get_user_profile().await;
    assert!(result.is_ok());
  }
}

#[tokio::test]
async fn update_user_profile_test() {
  if let Some(test) = FlowySupabaseTest::new() {
    let uuid = uuid::Uuid::new_v4().to_string();
    let profile = test.sign_up_with_uuid(&uuid).await;
    test
      .update_user_profile(UpdateUserProfilePayloadPB::new(profile.id).name("lucas"))
      .await;

    let new_profile = test.get_user_profile().await.unwrap();
    assert_eq!(new_profile.name, "lucas")
  }
}
