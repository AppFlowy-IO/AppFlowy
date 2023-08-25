use std::collections::HashMap;

use assert_json_diff::assert_json_eq;
use collab_document::blocks::DocumentData;
use collab_folder::core::FolderData;
use nanoid::nanoid;
use serde_json::json;

use flowy_core::DEFAULT_NAME;
use flowy_encrypt::decrypt_text;
use flowy_server::supabase::define::{USER_EMAIL, USER_UUID};
use flowy_test::document::document_event::DocumentEventTest;
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
async fn third_party_sign_up_with_encrypt_test() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    test.supabase_party_sign_up().await;
    let user_profile = test.get_user_profile().await.unwrap();
    assert!(user_profile.encryption_sign.is_empty());

    let secret = test.enable_encryption().await;
    let user_profile = test.get_user_profile().await.unwrap();
    assert!(!user_profile.encryption_sign.is_empty());

    let decryption_sign = decrypt_text(user_profile.encryption_sign, &secret).unwrap();
    assert_eq!(decryption_sign, user_profile.id.to_string());
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
    assert_eq!(error.code, ErrorCode::Conflict);
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
    assert_eq!(err.code, ErrorCode::RecordNotFound);
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
    assert_eq!(error.code, ErrorCode::Conflict);
  }
}

#[tokio::test]
async fn migrate_anon_document_on_cloud_signup() {
  if get_supabase_config().is_some() {
    let test = FlowyCoreTest::new();
    let user_profile = test.sign_up_as_guest().await.user_profile;

    let view = test
      .create_view(&user_profile.workspace_id, "My first view".to_string())
      .await;
    let document_event = DocumentEventTest::new_with_core(test.clone());
    let block_id = document_event
      .insert_index(&view.id, "hello world", 1, None)
      .await;

    let _ = test.supabase_party_sign_up().await;

    // After sign up, the documents should be migrated to the cloud
    // So, we can get the document data from the cloud
    let data: DocumentData = test
      .document_manager
      .get_cloud_service()
      .get_document_data(&view.id)
      .await
      .unwrap()
      .unwrap();
    let block = data.blocks.get(&block_id).unwrap();
    assert_json_eq!(
      block.data,
      json!({
        "delta": [
          {
            "insert": "hello world"
          }
        ]
      })
    );
  }
}

#[tokio::test]
async fn migrate_anon_data_on_cloud_signup() {
  if get_supabase_config().is_some() {
    let (cleaner, user_db_path) = unzip_history_user_db(
      "./tests/user/supabase_test/history_user_db",
      "workspace_sync",
    )
    .unwrap();
    let test = FlowyCoreTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string());
    let user_profile = test.supabase_party_sign_up().await;

    // Get the folder data from remote
    let folder_data: FolderData = test
      .folder_manager
      .get_cloud_service()
      .get_folder_data(&user_profile.workspace_id)
      .await
      .unwrap()
      .unwrap();
    let expected_folder_data = expected_workspace_sync_folder_data();

    assert_eq!(
      folder_data.workspaces.len(),
      expected_folder_data.workspaces.len()
    );
    assert_eq!(folder_data.views.len(), expected_folder_data.views.len());
    assert_eq!(folder_data.current_view, expected_folder_data.current_view);

    drop(cleaner);
  }
}

fn expected_workspace_sync_folder_data() -> FolderData {
  serde_json::from_value::<FolderData>(json!({
    "current_view": "82c5c683-5486-42c4-b4cb-92b114c6cf92",
    "current_workspace_id": "aaeb4fdd-6a06-489a-bde9-89e43a54302e",
    "views": [
      {
        "children": {
          "items": [
            {
              "id": "f0a76fd1-b769-42e8-829b-3cc33b088871"
            },
            {
              "id": "35067716-ddaa-4b18-a7f6-4c7ffd6753e8"
            }
          ]
        },
        "created_at": 1692884814,
        "desc": "",
        "icon": null,
        "id": "82c5c683-5486-42c4-b4cb-92b114c6cf92",
        "is_favorite": false,
        "layout": 0,
        "name": "⭐️ Getting started",
        "parent_view_id": "aaeb4fdd-6a06-489a-bde9-89e43a54302e"
      },
      {
        "children": {
          "items": [
            {
              "id": "028a34a6-0138-4aae-8116-896dd5ac8cb3"
            }
          ]
        },
        "created_at": 1692884817,
        "desc": "",
        "icon": null,
        "id": "f0a76fd1-b769-42e8-829b-3cc33b088871",
        "is_favorite": false,
        "layout": 0,
        "name": "document 1",
        "parent_view_id": "82c5c683-5486-42c4-b4cb-92b114c6cf92"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1692884946,
        "desc": "",
        "icon": null,
        "id": "028a34a6-0138-4aae-8116-896dd5ac8cb3",
        "is_favorite": false,
        "layout": 1,
        "name": "Untitled",
        "parent_view_id": "f0a76fd1-b769-42e8-829b-3cc33b088871"
      },
      {
        "children": {
          "items": [
            {
              "id": "9841041b-c7b0-4568-885c-24069b6d1d22"
            }
          ]
        },
        "created_at": 1692884827,
        "desc": "",
        "icon": null,
        "id": "35067716-ddaa-4b18-a7f6-4c7ffd6753e8",
        "is_favorite": false,
        "layout": 0,
        "name": "document 2",
        "parent_view_id": "82c5c683-5486-42c4-b4cb-92b114c6cf92"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1692884969,
        "desc": "",
        "icon": null,
        "id": "9841041b-c7b0-4568-885c-24069b6d1d22",
        "is_favorite": false,
        "layout": 0,
        "name": "Untitled",
        "parent_view_id": "35067716-ddaa-4b18-a7f6-4c7ffd6753e8"
      },
      {
        "children": {
          "items": [
            {
              "id": "6891352a-185c-4c0e-b66f-f7cb25a66033"
            },
            {
              "id": "e167e197-2822-4981-9391-86dff16fb261"
            }
          ]
        },
        "created_at": 1692884854,
        "desc": "",
        "icon": null,
        "id": "e53a478c-5911-4e82-9b24-3e8b01b8c3f3",
        "is_favorite": false,
        "layout": 0,
        "name": "database",
        "parent_view_id": "aaeb4fdd-6a06-489a-bde9-89e43a54302e"
      },
      {
        "children": {
          "items": [
            {
              "id": "b416d4a8-68d0-4a47-ba1f-091cbffaf9bf"
            },
            {
              "id": "c0d91451-fed0-4500-99a1-1ada9fe8aaaa"
            }
          ]
        },
        "created_at": 1692884857,
        "desc": "",
        "icon": null,
        "id": "6891352a-185c-4c0e-b66f-f7cb25a66033",
        "is_favorite": false,
        "layout": 1,
        "name": "My first database",
        "parent_view_id": "e53a478c-5911-4e82-9b24-3e8b01b8c3f3"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1692884875,
        "desc": "",
        "icon": null,
        "id": "b416d4a8-68d0-4a47-ba1f-091cbffaf9bf",
        "is_favorite": false,
        "layout": 3,
        "name": "calendar",
        "parent_view_id": "6891352a-185c-4c0e-b66f-f7cb25a66033"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1692884877,
        "desc": "",
        "icon": null,
        "id": "c0d91451-fed0-4500-99a1-1ada9fe8aaaa",
        "is_favorite": false,
        "layout": 2,
        "name": "board",
        "parent_view_id": "6891352a-185c-4c0e-b66f-f7cb25a66033"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1692884883,
        "desc": "",
        "icon": null,
        "id": "e167e197-2822-4981-9391-86dff16fb261",
        "is_favorite": false,
        "layout": 0,
        "name": "database description",
        "parent_view_id": "e53a478c-5911-4e82-9b24-3e8b01b8c3f3"
      }
    ],
    "workspaces": [
      {
        "child_views": {
          "items": [
            {
              "id": "82c5c683-5486-42c4-b4cb-92b114c6cf92"
            },
            {
              "id": "e53a478c-5911-4e82-9b24-3e8b01b8c3f3"
            }
          ]
        },
        "created_at": 1692884814,
        "id": "aaeb4fdd-6a06-489a-bde9-89e43a54302e",
        "name": "Workspace"
      }
    ]
  }))
  .unwrap()
}
