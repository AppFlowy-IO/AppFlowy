use std::collections::HashMap;

use nanoid::nanoid;

use flowy_server::supabase::define::{USER_EMAIL, USER_UUID};
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
    map.insert(USER_UUID.to_string(), uuid::Uuid::new_v4().to_string());
    map.insert(
      USER_EMAIL.to_string(),
      format!("{}@appflowy.io", nanoid!(6)),
    );
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
async fn third_party_sign_up_with_duplicated_uuid() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    let email = format!("{}@appflowy.io", nanoid!(6));
    let mut map = HashMap::new();
    map.insert(USER_UUID.to_string(), uuid::Uuid::new_v4().to_string());
    map.insert(USER_EMAIL.to_string(), email.clone());

    let response_1 = EventBuilder::new(test.clone())
      .event(ThirdPartyAuth)
      .payload(ThirdPartyAuthPB {
        map: map.clone(),
        auth_type: AuthTypePB::Supabase,
      })
      .async_send()
      .await
      .parse::<UserProfilePB>();
    dbg!(&response_1);

    let response_2 = EventBuilder::new(test.clone())
      .event(ThirdPartyAuth)
      .payload(ThirdPartyAuthPB {
        map: map.clone(),
        auth_type: AuthTypePB::Supabase,
      })
      .async_send()
      .await
      .parse::<UserProfilePB>();
    assert_eq!(response_1, response_2);
  };
}

#[tokio::test]
async fn third_party_sign_up_with_duplicated_email() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    let email = format!("{}@appflowy.io", nanoid!(6));
    test
      .third_party_sign_up_with_uuid(&uuid::Uuid::new_v4().to_string(), Some(email.clone()))
      .await
      .unwrap();
    let error = test
      .third_party_sign_up_with_uuid(&uuid::Uuid::new_v4().to_string(), Some(email.clone()))
      .await
      .err()
      .unwrap();
    assert_eq!(error.code, ErrorCode::Conflict.value());
  };
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
    test
      .third_party_sign_up_with_uuid(&uuid, None)
      .await
      .unwrap();
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
    let uuid = uuid::Uuid::new_v4().to_string();

    let email = format!("{}@appflowy.io", nanoid!(6));
    // The workspace of the guest will be migrated to the new user with given uuid
    let _user_profile = test
      .third_party_sign_up_with_uuid(&uuid, Some(email.clone()))
      .await
      .unwrap();
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

    let _sign_up_context = test.sign_up_as_guest().await;
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    test
      .create_view(&new_workspace.id, "new workspace child view".to_string())
      .await;
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    assert_eq!(new_workspace.views.len(), 2);

    // upload to cloud user with given uuid. This time the workspace of the guest will not be merged
    // because the cloud user already has a workspace
    test
      .third_party_sign_up_with_uuid(&uuid, Some(email))
      .await
      .unwrap();
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
    assert_eq!(err.code, ErrorCode::RecordNotFound.value());
  }
}

#[tokio::test]
async fn get_user_profile_test() {
  if let Some(test) = FlowySupabaseTest::new() {
    let uuid = uuid::Uuid::new_v4().to_string();
    test
      .third_party_sign_up_with_uuid(&uuid, None)
      .await
      .unwrap();

    let result = test.get_user_profile().await;
    assert!(result.is_ok());
  }
}

#[tokio::test]
async fn update_user_profile_test() {
  if let Some(test) = FlowySupabaseTest::new() {
    let uuid = uuid::Uuid::new_v4().to_string();
    let profile = test
      .third_party_sign_up_with_uuid(&uuid, None)
      .await
      .unwrap();
    test
      .update_user_profile(UpdateUserProfilePayloadPB::new(profile.id).name("lucas"))
      .await;

    let new_profile = test.get_user_profile().await.unwrap();
    assert_eq!(new_profile.name, "lucas")
  }
}

#[tokio::test]
async fn update_user_profile_with_existing_email_test() {
  if let Some(test) = FlowySupabaseTest::new() {
    let email = format!("{}@appflowy.io", nanoid!(6));
    let _ = test
      .third_party_sign_up_with_uuid(&uuid::Uuid::new_v4().to_string(), Some(email.clone()))
      .await;

    let profile = test
      .third_party_sign_up_with_uuid(
        &uuid::Uuid::new_v4().to_string(),
        Some(format!("{}@appflowy.io", nanoid!(6))),
      )
      .await
      .unwrap();
    let error = test
      .update_user_profile(
        UpdateUserProfilePayloadPB::new(profile.id)
          .name("lucas")
          .email(&email),
      )
      .await
      .unwrap();
    assert_eq!(error.code, ErrorCode::Conflict.value());
  }
}
