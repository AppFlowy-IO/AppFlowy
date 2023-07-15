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
async fn third_party_sign_up_test() {
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
async fn sign_up_as_guest_and_then_update_to_new_cloud_user_test() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new_with_guest_user().await;
    let old_views = test
      .folder_manager
      .get_current_workspace_views()
      .await
      .unwrap();
    let old_workspace = test.folder_manager.get_current_workspace().await.unwrap();

    let uuid = uuid::Uuid::new_v4().to_string();
    test.supabase_party_sign_up(&uuid).await;
    let new_views = test
      .folder_manager
      .get_current_workspace_views()
      .await
      .unwrap();
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();

    assert_eq!(old_views.len(), new_views.len());
    assert_eq!(old_workspace.name, new_workspace.name);
    assert_eq!(old_workspace.views.len(), new_workspace.views.len());
    for (index, view) in old_views.iter().enumerate() {
      assert_eq!(view.name, new_views[index].name);
      assert_eq!(view.id, new_views[index].id);
      assert_eq!(view.layout, new_views[index].layout);
      assert_eq!(view.create_time, new_views[index].create_time);
    }
  }
}

#[tokio::test]
async fn sign_up_as_guest_and_then_update_to_existing_cloud_user_test() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new_with_guest_user().await;
    let historical_users = test.user_session.sign_in_history();
    assert_eq!(historical_users.len(), 1);
    let uuid = uuid::Uuid::new_v4().to_string();

    // The workspace of the guest will be migrated to the new user with given uuid
    let user_profile = test.supabase_party_sign_up(&uuid).await;
    // let historical_users = test.user_session.sign_in_history(user_profile.id);
    // assert_eq!(historical_users.len(), 2);
    let old_cloud_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    let old_cloud_views = test
      .folder_manager
      .get_current_workspace_views()
      .await
      .unwrap();
    assert_eq!(old_cloud_views.len(), 1);
    assert_eq!(old_cloud_views.first().unwrap().child_views.len(), 1);

    // sign out and then sign in as a guest
    test.sign_out().await;
    // when sign out, the user profile will be not found
    let error = test
      .user_session
      .get_user_profile(user_profile.id, false)
      .await
      .err()
      .unwrap();
    assert_eq!(error.code, ErrorCode::RecordNotFound.value());

    let _sign_up_context = test.sign_up_as_guest().await;
    // assert_eq!(
    //   test
    //     .user_session
    //     .sign_in_history(sign_up_context.user_profile.id)
    //     .len(),
    //   3
    // );
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    test
      .create_view(&new_workspace.id, "new workspace child view".to_string())
      .await;
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    assert_eq!(new_workspace.views.len(), 2);

    // upload to cloud user with given uuid. This time the workspace of the guest will not be merged
    // because the cloud user already has a workspace
    test.supabase_party_sign_up(&uuid).await;
    // assert_eq!(test.user_session.sign_in_history().len(), 3);
    let new_cloud_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    let new_cloud_views = test
      .folder_manager
      .get_current_workspace_views()
      .await
      .unwrap();
    assert_eq!(new_cloud_workspace, old_cloud_workspace);
    assert_eq!(new_cloud_views, old_cloud_views);
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
