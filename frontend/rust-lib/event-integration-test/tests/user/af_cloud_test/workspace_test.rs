use crate::user::af_cloud_test::util::get_synced_workspaces;
use crate::util::unzip;
use collab::core::collab::DataSource::DocStateV1;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;
use collab_folder::Folder;
use event_integration_test::user_event::{use_local_mode, use_localhost_af_cloud};
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_user::entities::AFRolePB;
use flowy_user_pub::cloud::UserCloudServiceProvider;
use flowy_user_pub::entities::{AuthType, WorkspaceType};
use std::time::Duration;
use tokio::task::LocalSet;
use tokio::time::sleep;

#[tokio::test]
async fn af_cloud_workspace_delete() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let user_profile_pb = test.af_cloud_sign_up().await;
  let workspaces = get_synced_workspaces(&test, user_profile_pb.id).await;
  assert_eq!(workspaces.len(), 1);

  let created_workspace = test
    .create_workspace("my second workspace", WorkspaceType::Server)
    .await;
  assert_eq!(created_workspace.name, "my second workspace");
  let workspaces = get_synced_workspaces(&test, user_profile_pb.id).await;
  assert_eq!(workspaces.len(), 2);

  test.delete_workspace(&created_workspace.workspace_id).await;
  let workspaces = get_synced_workspaces(&test, user_profile_pb.id).await;
  assert_eq!(workspaces.len(), 1);

  let workspaces = test.get_all_workspaces().await.items;
  assert_eq!(workspaces.len(), 1);
}

#[tokio::test]
async fn af_cloud_workspace_change_name_and_icon() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let user_profile_pb = test.af_cloud_sign_up().await;
  let workspaces = test.get_all_workspaces().await;
  let workspace_id = workspaces.items[0].workspace_id.as_str();
  let new_workspace_name = "new_workspace_name".to_string();
  let new_icon = "🚀".to_string();
  test
    .rename_workspace(workspace_id, &new_workspace_name)
    .await
    .expect("failed to rename workspace");
  test
    .change_workspace_icon(workspace_id, &new_icon)
    .await
    .expect("failed to change workspace icon");
  let workspaces = get_synced_workspaces(&test, user_profile_pb.id).await;
  assert_eq!(workspaces[0].name, new_workspace_name);
  assert_eq!(workspaces[0].icon, new_icon);
  let local_workspaces = test.get_all_workspaces().await;
  assert_eq!(local_workspaces.items[0].name, new_workspace_name);
  assert_eq!(local_workspaces.items[0].icon, new_icon);
}

#[tokio::test]
async fn af_cloud_create_workspace_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let user_profile_pb = test.af_cloud_sign_up().await;

  let workspaces = test.get_all_workspaces().await.items;
  let first_workspace_id = workspaces[0].workspace_id.as_str();
  assert_eq!(workspaces.len(), 1);

  let created_workspace = test
    .create_workspace("my second workspace", WorkspaceType::Server)
    .await;
  assert_eq!(created_workspace.name, "my second workspace");

  let workspaces = get_synced_workspaces(&test, user_profile_pb.id).await;
  assert_eq!(workspaces.len(), 2);
  let _second_workspace = workspaces
    .iter()
    .find(|w| w.name == "my second workspace")
    .expect("created workspace not found");

  {
    // before opening new workspace
    let folder_ws = test.folder_read_current_workspace().await;
    assert_eq!(&folder_ws.id, first_workspace_id);
    let views = test.folder_read_current_workspace_views().await;
    assert_eq!(views.items[0].parent_view_id.as_str(), first_workspace_id);
  }
  {
    // after opening new workspace
    test
      .open_workspace(
        &created_workspace.workspace_id,
        created_workspace.workspace_type,
      )
      .await;
    let folder_ws = test.folder_read_current_workspace().await;
    assert_eq!(folder_ws.id, created_workspace.workspace_id);
    let views = test.folder_read_current_workspace_views().await;
    assert_eq!(
      views.items[0].parent_view_id.as_str(),
      created_workspace.workspace_id
    );
  }
}

#[tokio::test]
async fn af_cloud_open_workspace_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let _ = test.af_cloud_sign_up().await;
  let default_document_name = "General";

  test.create_document("A").await;
  test.create_document("B").await;
  let first_workspace = test.get_current_workspace().await;
  let first_workspace = test.get_user_workspace(&first_workspace.id).await;
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 4);
  assert_eq!(views[0].name, default_document_name);
  assert_eq!(views[1].name, "Shared");
  assert_eq!(views[2].name, "A");
  assert_eq!(views[3].name, "B");

  let user_workspace = test
    .create_workspace("second workspace", WorkspaceType::Server)
    .await;
  test
    .open_workspace(&user_workspace.workspace_id, user_workspace.workspace_type)
    .await;
  let second_workspace = test.get_current_workspace().await;
  let second_workspace = test.get_user_workspace(&second_workspace.id).await;
  test.create_document("C").await;
  test.create_document("D").await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 4);
  assert_eq!(views[0].name, default_document_name);
  assert_eq!(views[1].name, "Shared");
  assert_eq!(views[2].name, "C");
  assert_eq!(views[3].name, "D");

  // simulate open workspace and check if the views are correct
  for i in 0..10 {
    if i % 2 == 0 {
      test
        .open_workspace(
          &first_workspace.workspace_id,
          first_workspace.workspace_type,
        )
        .await;
      sleep(Duration::from_millis(300)).await;
      test
        .create_document(&uuid::Uuid::new_v4().to_string())
        .await;
    } else {
      test
        .open_workspace(
          &second_workspace.workspace_id,
          second_workspace.workspace_type,
        )
        .await;
      sleep(Duration::from_millis(200)).await;
      test
        .create_document(&uuid::Uuid::new_v4().to_string())
        .await;
    }
  }

  test
    .open_workspace(
      &first_workspace.workspace_id,
      first_workspace.workspace_type,
    )
    .await;
  let views_1 = test.get_all_workspace_views().await;
  assert_eq!(views_1[0].name, default_document_name);
  assert_eq!(views_1[1].name, "Shared");
  assert_eq!(views_1[2].name, "A");
  assert_eq!(views_1[3].name, "B");

  test
    .open_workspace(
      &second_workspace.workspace_id,
      second_workspace.workspace_type,
    )
    .await;
  let views_2 = test.get_all_workspace_views().await;
  assert_eq!(views_2[0].name, default_document_name);
  assert_eq!(views_2[1].name, "Shared");
  assert_eq!(views_2[2].name, "C");
  assert_eq!(views_2[3].name, "D");
}

#[tokio::test]
async fn af_cloud_different_open_same_workspace_test() {
  use_localhost_af_cloud().await;

  // Set up the primary client and sign them up to the cloud.
  let test_runner = EventIntegrationTest::new().await;
  let owner_profile = test_runner.af_cloud_sign_up().await;
  let shared_workspace_id = test_runner.get_current_workspace().await.id.clone();

  // Define the number of additional clients
  let num_clients = 5;
  let mut clients = Vec::new();

  // Initialize and sign up additional clients
  for _ in 0..num_clients {
    let client = EventIntegrationTest::new().await;
    let client_profile = client.af_cloud_sign_up().await;

    let views = client.get_all_workspace_views().await;
    // only the getting started view should be present
    assert_eq!(views.len(), 2);
    for view in views {
      client.delete_view(&view.id).await;
    }

    test_runner
      .add_workspace_member(&shared_workspace_id, &client)
      .await;
    clients.push((client, client_profile));
  }

  // Verify that each client has exactly two workspaces: one from sign-up and another from invitation
  for (client, profile) in &clients {
    let all_workspaces = get_synced_workspaces(client, profile.id).await;
    assert_eq!(all_workspaces.len(), 2);
  }

  // Simulate each client open different workspace 30 times
  let mut handles = vec![];
  let local_set = LocalSet::new();
  for client in clients.clone() {
    let cloned_shared_workspace_id = shared_workspace_id.clone();
    let handle = local_set.spawn_local(async move {
      let (client, profile) = client;
      let all_workspaces = get_synced_workspaces(&client, profile.id).await;
      for i in 0..30 {
        let index = i % 2;
        let iter_workspace_id = &all_workspaces[index].workspace_id;
        client
          .open_workspace(iter_workspace_id, all_workspaces[index].workspace_type)
          .await;
        if iter_workspace_id == &cloned_shared_workspace_id {
          let views = client.get_all_workspace_views().await;
          assert_eq!(views.len(), 2);
          sleep(Duration::from_millis(300)).await;
        } else {
          let views = client.get_all_workspace_views().await;
          assert!(views.is_empty());
        }
      }
    });
    handles.push(handle);
  }
  let results = local_set
    .run_until(futures::future::join_all(handles))
    .await;

  for result in results {
    assert!(result.is_ok());
  }

  // Retrieve and verify the collaborative document state for Client 1's workspace.
  let doc_state = test_runner
    .get_collab_doc_state(&shared_workspace_id, CollabType::Folder)
    .await
    .unwrap();
  let folder = Folder::from_collab_doc_state(
    owner_profile.id,
    CollabOrigin::Empty,
    DocStateV1(doc_state),
    &shared_workspace_id,
    vec![],
  )
  .unwrap();

  // Retrieve and verify the views associated with the workspace.
  let views = folder.get_views_belong_to(&shared_workspace_id);
  let folder_workspace_id = folder.get_workspace_id();
  assert_eq!(folder_workspace_id, Some(shared_workspace_id));

  assert_eq!(views.len(), 2, "only get: {:?}", views); // Expecting two views.
  assert_eq!(views[0].name, "General");
}

#[tokio::test]
async fn af_cloud_create_local_workspace_test() {
  // Setup: Initialize test environment with AppFlowyCloud
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let _ = test.af_cloud_sign_up().await;

  // Verify initial state: User should have one default workspace
  let initial_workspaces = test.get_all_workspaces().await.items;
  assert_eq!(
    initial_workspaces.len(),
    1,
    "User should start with one default workspace"
  );

  // make sure the workspaces order is consistent
  // tokio::time::sleep(tokio::time::Duration::from_secs(10)).await;

  // Test: Create a local workspace
  let local_workspace = test
    .create_workspace("my local workspace", WorkspaceType::Local)
    .await;

  // Verify: Local workspace was created correctly
  assert_eq!(local_workspace.name, "my local workspace");
  let updated_workspaces = test.get_all_workspaces().await.items;
  assert_eq!(
    updated_workspaces.len(),
    2,
    "Should now have two workspaces"
  );
  dbg!(&updated_workspaces);

  // Find local workspace by name instead of using index
  let found_local_workspace = updated_workspaces
    .iter()
    .find(|workspace| workspace.name == "my local workspace")
    .expect("Local workspace should exist");
  assert_eq!(found_local_workspace.name, "my local workspace");

  // Test: Open the local workspace
  test
    .open_workspace(
      &local_workspace.workspace_id,
      local_workspace.workspace_type,
    )
    .await;

  // Verify: Views in the local workspace
  let views = test.get_all_views().await;
  assert_eq!(
    views.len(),
    3,
    "Local workspace should have 3 default views"
  );
  assert!(
    views
      .iter()
      .any(|view| view.parent_view_id == local_workspace.workspace_id),
    "Views should belong to the local workspace"
  );

  // Verify: Can access all views
  for view in views {
    test.get_view(&view.id).await;
  }

  // Verify: Local workspace members
  let members = test
    .get_workspace_members(&local_workspace.workspace_id)
    .await;
  assert_eq!(
    members.len(),
    1,
    "Local workspace should have only one member"
  );
  assert_eq!(members[0].role, AFRolePB::Owner, "User should be the owner");

  // Test: Create a server workspace
  let server_workspace = test
    .create_workspace("my server workspace", WorkspaceType::Server)
    .await;

  // Verify: Server workspace was created correctly
  assert_eq!(server_workspace.name, "my server workspace");
  let final_workspaces = test.get_all_workspaces().await.items;
  assert_eq!(
    final_workspaces.len(),
    3,
    "Should now have three workspaces"
  );

  dbg!(&final_workspaces);

  // Find workspaces by name instead of using indices
  let found_local_workspace = final_workspaces
    .iter()
    .find(|workspace| workspace.name == "my local workspace")
    .expect("Local workspace should exist");
  assert_eq!(found_local_workspace.name, "my local workspace");

  let found_server_workspace = final_workspaces
    .iter()
    .find(|workspace| workspace.name == "my server workspace")
    .expect("Server workspace should exist");
  assert_eq!(found_server_workspace.name, "my server workspace");

  // Verify: Server-side only recognizes cloud workspaces (not local ones)
  let user_profile = test.get_user_profile().await.unwrap();
  test
    .server_provider
    .set_server_auth_type(&AuthType::AppFlowyCloud, Some(user_profile.token.clone()))
    .unwrap();
  test.server_provider.set_token(&user_profile.token).unwrap();

  let user_service = test.server_provider.get_server().unwrap().user_service();
  let server_workspaces = user_service
    .get_all_workspace(user_profile.id)
    .await
    .unwrap();
  assert_eq!(
    server_workspaces.len(),
    2,
    "Server should only see 2 workspaces (the default and server workspace, not the local one)"
  );
}

#[tokio::test]
async fn af_cloud_open_089_anon_user_data_folder_test() {
  let user_db_path = unzip("./tests/asset", "089_local").unwrap();
  use_localhost_af_cloud().await;
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  // After 0.8.9, we store user workspace into user_workspace_table and refactor the Session serde struct
  // So, if everything is correct, we should be able to open the workspace and get the views
  let workspaces = test.get_all_workspaces().await.items;
  let views = test.get_all_views().await;
  dbg!(&views);
  assert!(views.iter().any(|view| view.name == "Anon 089  document"));
  assert_eq!(workspaces.len(), 1);
}

#[tokio::test]
async fn open_089_anon_user_data_folder_test() {
  use_local_mode().await;
  // Almost same as af_cloud_open_089_anon_user_data_folder_test but doesn't use af_cloud as the backend
  let user_db_path = unzip("./tests/asset", "089_local").unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;
  let workspaces = test.get_all_workspaces().await.items;
  let views = test.get_all_views().await;
  dbg!(&views);
  assert!(views.iter().any(|view| view.name == "Anon 089  document"));
  assert_eq!(workspaces.len(), 1);
}
