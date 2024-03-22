use std::collections::HashMap;

use assert_json_diff::assert_json_eq;
use collab_database::rows::database_row_document_id_from_row_id;
use collab_document::blocks::DocumentData;
use collab_entity::CollabType;
use collab_folder::FolderData;
use nanoid::nanoid;
use serde_json::json;

use event_integration::document::document_event::DocumentEventTest;
use event_integration::event_builder::EventBuilder;
use event_integration::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_encrypt::decrypt_text;
use flowy_server::supabase::define::{USER_DEVICE_ID, USER_EMAIL, USER_UUID};
use flowy_user::entities::{
  AuthenticatorPB, OauthSignInPB, UpdateUserProfilePayloadPB, UserProfilePB,
};
use flowy_user::errors::ErrorCode;
use flowy_user::event_map::UserEvent::*;

use crate::util::*;

#[tokio::test]
async fn third_party_sign_up_test() {
  if get_supabase_config().is_some() {
    let test = EventIntegrationTest::new().await;
    let mut map = HashMap::new();
    map.insert(USER_UUID.to_string(), uuid::Uuid::new_v4().to_string());
    map.insert(
      USER_EMAIL.to_string(),
      format!("{}@appflowy.io", nanoid!(6)),
    );
    map.insert(USER_DEVICE_ID.to_string(), uuid::Uuid::new_v4().to_string());
    let payload = OauthSignInPB {
      map,
      authenticator: AuthenticatorPB::Supabase,
    };

    let response = EventBuilder::new(test.clone())
      .event(OauthSignIn)
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
    let test = EventIntegrationTest::new().await;
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
    let test = EventIntegrationTest::new().await;
    let email = format!("{}@appflowy.io", nanoid!(6));
    let mut map = HashMap::new();
    map.insert(USER_UUID.to_string(), uuid::Uuid::new_v4().to_string());
    map.insert(USER_EMAIL.to_string(), email.clone());
    map.insert(USER_DEVICE_ID.to_string(), uuid::Uuid::new_v4().to_string());

    let response_1 = EventBuilder::new(test.clone())
      .event(OauthSignIn)
      .payload(OauthSignInPB {
        map: map.clone(),
        authenticator: AuthenticatorPB::Supabase,
      })
      .async_send()
      .await
      .parse::<UserProfilePB>();
    dbg!(&response_1);

    let response_2 = EventBuilder::new(test.clone())
      .event(OauthSignIn)
      .payload(OauthSignInPB {
        map: map.clone(),
        authenticator: AuthenticatorPB::Supabase,
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
    let test = EventIntegrationTest::new().await;
    let email = format!("{}@appflowy.io", nanoid!(6));
    test
      .supabase_sign_up_with_uuid(&uuid::Uuid::new_v4().to_string(), Some(email.clone()))
      .await
      .unwrap();
    let error = test
      .supabase_sign_up_with_uuid(&uuid::Uuid::new_v4().to_string(), Some(email.clone()))
      .await
      .err()
      .unwrap();
    assert_eq!(error.code, ErrorCode::Conflict);
  };
}

#[tokio::test]
async fn sign_up_as_guest_and_then_update_to_new_cloud_user_test() {
  if get_supabase_config().is_some() {
    let test = EventIntegrationTest::new_anon().await;
    let old_views = test
      .folder_manager
      .get_current_workspace_public_views()
      .await
      .unwrap();
    let old_workspace = test.folder_manager.get_current_workspace().await.unwrap();

    let uuid = uuid::Uuid::new_v4().to_string();
    test.supabase_sign_up_with_uuid(&uuid, None).await.unwrap();
    let new_views = test
      .folder_manager
      .get_current_workspace_public_views()
      .await
      .unwrap();
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();

    assert_eq!(old_views.len(), new_views.len());
    assert_eq!(old_workspace.name, new_workspace.name);
    assert_eq!(old_workspace.views.len(), new_workspace.views.len());
    for (index, view) in old_views.iter().enumerate() {
      assert_eq!(view.name, new_views[index].name);
      assert_eq!(view.layout, new_views[index].layout);
      assert_eq!(view.create_time, new_views[index].create_time);
    }
  }
}

#[tokio::test]
async fn sign_up_as_guest_and_then_update_to_existing_cloud_user_test() {
  if get_supabase_config().is_some() {
    let test = EventIntegrationTest::new_anon().await;
    let uuid = uuid::Uuid::new_v4().to_string();

    let email = format!("{}@appflowy.io", nanoid!(6));
    // The workspace of the guest will be migrated to the new user with given uuid
    let _user_profile = test
      .supabase_sign_up_with_uuid(&uuid, Some(email.clone()))
      .await
      .unwrap();
    let old_cloud_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    let old_cloud_views = test
      .folder_manager
      .get_current_workspace_public_views()
      .await
      .unwrap();
    assert_eq!(old_cloud_views.len(), 1);
    assert_eq!(old_cloud_views.first().unwrap().child_views.len(), 1);

    // sign out and then sign in as a guest
    test.sign_out().await;

    let _sign_up_context = test.sign_up_as_anon().await;
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    test
      .create_view(&new_workspace.id, "new workspace child view".to_string())
      .await;
    let new_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    assert_eq!(new_workspace.views.len(), 2);

    // upload to cloud user with given uuid. This time the workspace of the guest will not be merged
    // because the cloud user already has a workspace
    test
      .supabase_sign_up_with_uuid(&uuid, Some(email))
      .await
      .unwrap();
    let new_cloud_workspace = test.folder_manager.get_current_workspace().await.unwrap();
    let new_cloud_views = test
      .folder_manager
      .get_current_workspace_public_views()
      .await
      .unwrap();
    assert_eq!(new_cloud_workspace, old_cloud_workspace);
    assert_eq!(new_cloud_views, old_cloud_views);
  }
}

#[tokio::test]
async fn get_user_profile_test() {
  if let Some(test) = FlowySupabaseTest::new().await {
    let uuid = uuid::Uuid::new_v4().to_string();
    test.supabase_sign_up_with_uuid(&uuid, None).await.unwrap();

    let result = test.get_user_profile().await;
    assert!(result.is_ok());
  }
}

#[tokio::test]
async fn update_user_profile_test() {
  if let Some(test) = FlowySupabaseTest::new().await {
    let uuid = uuid::Uuid::new_v4().to_string();
    let profile = test.supabase_sign_up_with_uuid(&uuid, None).await.unwrap();
    test
      .update_user_profile(UpdateUserProfilePayloadPB::new(profile.id).name("lucas"))
      .await;

    let new_profile = test.get_user_profile().await.unwrap();
    assert_eq!(new_profile.name, "lucas")
  }
}

#[tokio::test]
async fn update_user_profile_with_existing_email_test() {
  if let Some(test) = FlowySupabaseTest::new().await {
    let email = format!("{}@appflowy.io", nanoid!(6));
    let _ = test
      .supabase_sign_up_with_uuid(&uuid::Uuid::new_v4().to_string(), Some(email.clone()))
      .await;

    let profile = test
      .supabase_sign_up_with_uuid(
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
    let test = EventIntegrationTest::new().await;
    let user_profile = test.sign_up_as_anon().await.user_profile;

    let view = test
      .create_view(&user_profile.workspace_id, "My first view".to_string())
      .await;
    let document_event = DocumentEventTest::new_with_core(test.clone());
    let block_id = document_event
      .insert_index(&view.id, "hello world", 1, None)
      .await;

    let _ = test.supabase_party_sign_up().await;

    let workspace_id = test.user_manager.workspace_id().unwrap();
    // After sign up, the documents should be migrated to the cloud
    // So, we can get the document data from the cloud
    let data: DocumentData = test
      .document_manager
      .get_cloud_service()
      .get_document_data(&view.id, &workspace_id)
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
    let (cleaner, user_db_path) = unzip(
      "./tests/user/supabase_test/history_user_db",
      "workspace_sync",
    )
    .unwrap();
    let test =
      EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;
    let user_profile = test.supabase_party_sign_up().await;

    // Get the folder data from remote
    let folder_data: FolderData = test
      .folder_manager
      .get_cloud_service()
      .get_folder_data(&user_profile.workspace_id, &user_profile.id)
      .await
      .unwrap()
      .unwrap();

    let expected_folder_data = expected_workspace_sync_folder_data();
    assert_eq!(folder_data.views.len(), expected_folder_data.views.len());

    // After migration, the ids of the folder_data should be different from the expected_folder_data
    for i in 0..folder_data.views.len() {
      let left_view = &folder_data.views[i];
      let right_view = &expected_folder_data.views[i];
      assert_ne!(left_view.id, right_view.id);
      assert_ne!(left_view.parent_view_id, right_view.parent_view_id);
      assert_eq!(left_view.name, right_view.name);
    }

    assert_ne!(folder_data.workspace.id, expected_folder_data.workspace.id);
    assert_ne!(folder_data.current_view, expected_folder_data.current_view);

    let database_views = folder_data
      .views
      .iter()
      .filter(|view| view.layout.is_database())
      .collect::<Vec<_>>();

    // Try to load the database from the cloud.
    for (i, database_view) in database_views.iter().enumerate() {
      let cloud_service = test.database_manager.get_cloud_service();
      let database_id = test
        .database_manager
        .get_database_id_with_view_id(&database_view.id)
        .await
        .unwrap();
      let editor = test
        .database_manager
        .get_database(&database_id)
        .await
        .unwrap();

      // The database view setting should be loaded by the view id
      let _ = editor
        .get_database_view_setting(&database_view.id)
        .await
        .unwrap();

      let rows = editor.get_rows(&database_view.id).await.unwrap();
      assert_eq!(rows.len(), 3);

      let workspace_id = test.user_manager.workspace_id().unwrap();
      if i == 0 {
        let first_row = rows.first().unwrap().as_ref();
        let icon_url = first_row.meta.icon_url.clone().unwrap();
        assert_eq!(icon_url, "😄");

        let document_id = database_row_document_id_from_row_id(&first_row.row.id);
        let document_data: DocumentData = test
          .document_manager
          .get_cloud_service()
          .get_document_data(&document_id, &workspace_id)
          .await
          .unwrap()
          .unwrap();

        let editor = test
          .document_manager
          .get_document(&document_id)
          .await
          .unwrap();
        let expected_document_data = editor.lock().get_document_data().unwrap();

        // let expected_document_data = test
        //   .document_manager
        //   .get_document_data(&document_id)
        //   .await
        //   .unwrap();
        assert_eq!(document_data, expected_document_data);
        let json = json!(document_data);
        assert_eq!(
          json["blocks"]["LPMpo0Qaab"]["data"]["delta"][0]["insert"],
          json!("Row document")
        );
      }
      assert!(cloud_service
        .get_database_object_doc_state(&database_id, CollabType::Database, &workspace_id)
        .await
        .is_ok());
    }

    drop(cleaner);
  }
}

fn expected_workspace_sync_folder_data() -> FolderData {
  serde_json::from_value::<FolderData>(json!({
    "current_view": "e0811131-9928-4541-a174-20b7553d9e4c",
    "current_workspace_id": "8df7f755-fa5d-480e-9f8e-48ea0fed12b3",
    "views": [
      {
        "children": {
          "items": [
            {
              "id": "e0811131-9928-4541-a174-20b7553d9e4c"
            },
            {
              "id": "53333949-c262-447b-8597-107589697059"
            }
          ]
        },
        "created_at": 1693147093,
        "desc": "",
        "icon": null,
        "id": "e203afb3-de5d-458a-8380-33cd788a756e",
        "is_favorite": false,
        "layout": 0,
        "name": "⭐️ Getting started",
        "parent_view_id": "8df7f755-fa5d-480e-9f8e-48ea0fed12b3"
      },
      {
        "children": {
          "items": [
            {
              "id": "11c697ba-5ed1-41c0-adfc-576db28ad27b"
            },
            {
              "id": "4a5c25e2-a734-440c-973b-4c0e7ab0039c"
            }
          ]
        },
        "created_at": 1693147096,
        "desc": "",
        "icon": null,
        "id": "e0811131-9928-4541-a174-20b7553d9e4c",
        "is_favorite": false,
        "layout": 1,
        "name": "database",
        "parent_view_id": "e203afb3-de5d-458a-8380-33cd788a756e"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1693147124,
        "desc": "",
        "icon": null,
        "id": "11c697ba-5ed1-41c0-adfc-576db28ad27b",
        "is_favorite": false,
        "layout": 3,
        "name": "calendar",
        "parent_view_id": "e0811131-9928-4541-a174-20b7553d9e4c"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1693147125,
        "desc": "",
        "icon": null,
        "id": "4a5c25e2-a734-440c-973b-4c0e7ab0039c",
        "is_favorite": false,
        "layout": 2,
        "name": "board",
        "parent_view_id": "e0811131-9928-4541-a174-20b7553d9e4c"
      },
      {
        "children": {
          "items": []
        },
        "created_at": 1693147133,
        "desc": "",
        "icon": null,
        "id": "53333949-c262-447b-8597-107589697059",
        "is_favorite": false,
        "layout": 0,
        "name": "document",
        "parent_view_id": "e203afb3-de5d-458a-8380-33cd788a756e"
      }
    ],
    "workspaces": [
      {
        "child_views": {
          "items": [
            {
              "id": "e203afb3-de5d-458a-8380-33cd788a756e"
            }
          ]
        },
        "created_at": 1693147093,
        "id": "8df7f755-fa5d-480e-9f8e-48ea0fed12b3",
        "name": "Workspace"
      }
    ]
  }))
  .unwrap()
}
