use std::time::Duration;

use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;
use flowy_user::entities::RepeatedUserWorkspacePB;
use flowy_user::protobuf::UserNotification;

use crate::util::receive_with_timeout;

#[tokio::test]
async fn af_cloud_create_workspace_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let user_profile_pb = test.af_cloud_sign_up().await;

  let workspaces = test.get_all_workspaces().await.items;
  assert_eq!(workspaces.len(), 1);

  test.create_workspace("my second workspace").await;
  let _workspaces = test.get_all_workspaces().await.items;

  let a = user_profile_pb.id.to_string();
  let rx = test
    .notification_sender
    .subscribe::<RepeatedUserWorkspacePB>(&a, UserNotification::DidUpdateUserWorkspaces as i32);
  let workspaces = receive_with_timeout(rx, Duration::from_secs(30))
    .await
    .unwrap()
    .items;

  assert_eq!(workspaces.len(), 2);
  assert_eq!(workspaces[1].name, "my second workspace".to_string());
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
