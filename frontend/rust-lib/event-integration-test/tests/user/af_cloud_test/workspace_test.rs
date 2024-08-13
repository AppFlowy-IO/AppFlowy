use collab::core::collab::DataSource::DocStateV1;
use collab::core::origin::CollabOrigin;
use collab_entity::CollabType;
use collab_folder::Folder;
use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use std::time::Duration;
use tokio::task::LocalSet;
use tokio::time::sleep;

use crate::user::af_cloud_test::util::get_synced_workspaces;

#[tokio::test]
async fn af_cloud_workspace_delete() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let user_profile_pb = test.af_cloud_sign_up().await;
  let workspaces = get_synced_workspaces(&test, user_profile_pb.id).await;
  assert_eq!(workspaces.len(), 1);

  let created_workspace = test.create_workspace("my second workspace").await;
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
  user_localhost_af_cloud().await;
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
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let user_profile_pb = test.af_cloud_sign_up().await;

  let workspaces = test.get_all_workspaces().await.items;
  let first_workspace_id = workspaces[0].workspace_id.as_str();
  assert_eq!(workspaces.len(), 1);

  let created_workspace = test.create_workspace("my second workspace").await;
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
    test.open_workspace(&created_workspace.workspace_id).await;
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
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let _ = test.af_cloud_sign_up().await;
  let default_document_name = "Getting started";

  test.create_document("A").await;
  test.create_document("B").await;
  let first_workspace = test.get_current_workspace().await;
  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  assert_eq!(views[0].name, default_document_name);
  assert_eq!(views[1].name, "A");
  assert_eq!(views[2].name, "B");

  let user_workspace = test.create_workspace("second workspace").await;
  test.open_workspace(&user_workspace.workspace_id).await;
  let second_workspace = test.get_current_workspace().await;
  test.create_document("C").await;
  test.create_document("D").await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  assert_eq!(views[0].name, default_document_name);
  assert_eq!(views[1].name, "C");
  assert_eq!(views[2].name, "D");

  // simulate open workspace and check if the views are correct
  for i in 0..30 {
    if i % 2 == 0 {
      test.open_workspace(&first_workspace.id).await;
      sleep(Duration::from_millis(300)).await;
      test
        .create_document(&uuid::Uuid::new_v4().to_string())
        .await;
    } else {
      test.open_workspace(&second_workspace.id).await;
      sleep(Duration::from_millis(200)).await;
      test
        .create_document(&uuid::Uuid::new_v4().to_string())
        .await;
    }
  }

  test.open_workspace(&first_workspace.id).await;
  let views = test.get_all_workspace_views().await;
  assert_eq!(views[0].name, default_document_name);
  assert_eq!(views[1].name, "A");
  assert_eq!(views[2].name, "B");

  test.open_workspace(&second_workspace.id).await;
  let views = test.get_all_workspace_views().await;
  assert_eq!(views[0].name, default_document_name);
  assert_eq!(views[1].name, "C");
  assert_eq!(views[2].name, "D");
}

#[tokio::test]
async fn af_cloud_different_open_same_workspace_test() {
  user_localhost_af_cloud().await;

  // Set up the primary client and sign them up to the cloud.
  let test_runner = EventIntegrationTest::new().await;
  let owner_profile = test_runner.af_cloud_sign_up().await;
  let shared_workspace_id = test_runner.get_current_workspace().await.id.clone();

  // Verify that the workspace ID from the profile matches the current session's workspace ID.
  assert_eq!(shared_workspace_id, owner_profile.workspace_id);

  // Define the number of additional clients
  let num_clients = 5;
  let mut clients = Vec::new();

  // Initialize and sign up additional clients
  for _ in 0..num_clients {
    let client = EventIntegrationTest::new().await;
    let client_profile = client.af_cloud_sign_up().await;

    let views = client.get_all_workspace_views().await;
    // only the getting started view should be present
    assert_eq!(views.len(), 1);
    for view in views {
      client.delete_view(&view.id).await;
    }

    test_runner
      .add_workspace_member(&owner_profile.workspace_id, &client)
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
        client.open_workspace(iter_workspace_id).await;
        if iter_workspace_id == &cloned_shared_workspace_id {
          let views = client.get_all_workspace_views().await;
          assert_eq!(views.len(), 1);
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
  assert_eq!(folder_workspace_id, shared_workspace_id);

  assert_eq!(views.len(), 1, "only get: {:?}", views); // Expecting two views.
  assert_eq!(views[0].name, "Getting started");
}
