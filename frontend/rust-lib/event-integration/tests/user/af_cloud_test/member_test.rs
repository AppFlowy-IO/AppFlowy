use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;

#[tokio::test]
async fn af_cloud_add_workspace_member_test() {
  user_localhost_af_cloud().await;
  let test_1 = EventIntegrationTest::new().await;
  let user_1 = test_1.af_cloud_sign_up().await;

  let test_2 = EventIntegrationTest::new().await;
  let user_2 = test_2.af_cloud_sign_up().await;

  let members = test_1.get_workspace_members(&user_1.workspace_id).await;
  assert_eq!(members.len(), 1);
  assert_eq!(members[0].email, user_1.email);

  test_1
    .add_workspace_member(&user_1.workspace_id, &user_2.email)
    .await;

  let members = test_1.get_workspace_members(&user_1.workspace_id).await;
  assert_eq!(members.len(), 2);
  assert_eq!(members[0].email, user_1.email);
  assert_eq!(members[1].email, user_2.email);
}

#[tokio::test]
async fn af_cloud_delete_workspace_member_test() {
  user_localhost_af_cloud().await;
  let test_1 = EventIntegrationTest::new().await;
  let user_1 = test_1.af_cloud_sign_up().await;

  let test_2 = EventIntegrationTest::new().await;
  let user_2 = test_2.af_cloud_sign_up().await;

  test_1
    .add_workspace_member(&user_1.workspace_id, &user_2.email)
    .await;

  test_1
    .delete_workspace_member(&user_1.workspace_id, &user_2.email)
    .await;

  let members = test_1.get_workspace_members(&user_1.workspace_id).await;
  assert_eq!(members.len(), 1);
  assert_eq!(members[0].email, user_1.email);
}
