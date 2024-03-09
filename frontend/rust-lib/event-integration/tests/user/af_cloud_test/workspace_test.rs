use std::time::Duration;

use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;
use flowy_user::entities::{RepeatedUserWorkspacePB, UserWorkspacePB};
use flowy_user::protobuf::UserNotification;

use crate::util::receive_with_timeout;

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
async fn af_cloud_workspace_name_change() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let user_profile_pb = test.af_cloud_sign_up().await;
  let workspaces = test.get_all_workspaces().await;
  let workspace_id = workspaces.items[0].workspace_id.as_str();
  test
    .rename_workspace(workspace_id, "new_workspace_name")
    .await
    .expect("failed to rename workspace");
  let workspaces = get_synced_workspaces(&test, user_profile_pb.id).await;
  assert_eq!(workspaces[0].name, "new_workspace_name".to_string());
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
  assert_eq!(workspaces[1].name, "my second workspace".to_string());

  {
    // before opening new workspace
    let folder_ws = test.folder_read_current_workspace().await;
    assert_eq!(&folder_ws.id, first_workspace_id);
    let views = test.folder_read_workspace_views().await;
    assert_eq!(views.items[0].parent_view_id.as_str(), first_workspace_id);
  }
  {
    // after opening new workspace
    test.open_workspace(&created_workspace.workspace_id).await;
    let folder_ws = test.folder_read_current_workspace().await;
    assert_eq!(folder_ws.id, created_workspace.workspace_id);
    let views = test.folder_read_workspace_views().await;
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

  let workspace = test.create_workspace("my second workspace").await;
  test.open_workspace(&workspace.workspace_id).await;

  test.create_document("my first document").await;
  test.create_document("my second document").await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  // the first view is the default get started view
  assert_eq!(views[1].name, "my first document".to_string());
  assert_eq!(views[2].name, "my second document".to_string());
}

async fn get_synced_workspaces(test: &EventIntegrationTest, user_id: i64) -> Vec<UserWorkspacePB> {
  let _workspaces = test.get_all_workspaces().await.items;
  let sub_id = user_id.to_string();
  let rx = test
    .notification_sender
    .subscribe::<RepeatedUserWorkspacePB>(
      &sub_id,
      UserNotification::DidUpdateUserWorkspaces as i32,
    );
  receive_with_timeout(rx, Duration::from_secs(30))
    .await
    .unwrap()
    .items
}
