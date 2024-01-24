use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;

#[tokio::test]
async fn af_cloud_create_workspace_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let _ = test.af_cloud_sign_up().await;

  let workspaces = test.get_all_workspaces().await.items;
  assert_eq!(workspaces.len(), 1);

  test.create_workspace("my second workspace").await;
  let workspaces = test.get_all_workspaces().await.items;
  assert_eq!(workspaces.len(), 2);
  assert_eq!(workspaces[1].name, "my second workspace".to_string());
}
