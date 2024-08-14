use crate::user::af_cloud_test::util::get_synced_workspaces;
use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;

#[tokio::test]
async fn af_cloud_invite_workspace_member() {
  /*
  this test will fail because the github secret is not available for PRs.
  user_localhost_af_cloud().await;
  let test_1 = EventIntegrationTest::new().await;
  let user_1 = test_1.af_cloud_sign_up().await;

  let test_2 = EventIntegrationTest::new().await;
  let user_2 = test_2.af_cloud_sign_up().await;

  test_1
    .invite_workspace_member(&user_1.workspace_id, &user_2.email, Role::Member)
    .await;

  let invitations = test_2.list_workspace_invitations().await;
  let target_invi = invitations
    .items
    .into_iter()
    .find(|i| i.inviter_name == user_1.name && i.workspace_id == user_1.workspace_id)
    .unwrap();

  test_2
    .accept_workspace_invitation(&target_invi.invite_id)
    .await;

  let workspaces = get_synced_workspaces(&test_2, user_2.id).await;
  assert_eq!(workspaces.len(), 2);
   */
}

#[tokio::test]
async fn af_cloud_add_workspace_member_test() {
  user_localhost_af_cloud().await;
  let test_1 = EventIntegrationTest::new().await;
  let user_1 = test_1.af_cloud_sign_up().await;
  let workspace_id_1 = test_1.get_current_workspace().await.id;

  let test_2 = EventIntegrationTest::new().await;
  let user_2 = test_2.af_cloud_sign_up().await;

  let members = test_1.get_workspace_members(&workspace_id_1).await;
  assert_eq!(members.len(), 1);
  assert_eq!(members[0].email, user_1.email);

  test_1.add_workspace_member(&workspace_id_1, &test_2).await;

  let members = test_1.get_workspace_members(&workspace_id_1).await;
  assert_eq!(members.len(), 2);
  assert_eq!(members[0].email, user_1.email);
  assert_eq!(members[1].email, user_2.email);
}

#[tokio::test]
async fn af_cloud_delete_workspace_member_test() {
  user_localhost_af_cloud().await;
  let test_1 = EventIntegrationTest::new().await;
  let user_1 = test_1.af_cloud_sign_up().await;
  let workspace_id_1 = test_1.get_current_workspace().await.id;

  let test_2 = EventIntegrationTest::new().await;
  let user_2 = test_2.af_cloud_sign_up().await;

  test_1.add_workspace_member(&workspace_id_1, &test_2).await;

  test_1
    .delete_workspace_member(&workspace_id_1, &user_2.email)
    .await;

  let members = test_1.get_workspace_members(&workspace_id_1).await;
  assert_eq!(members.len(), 1);
  assert_eq!(members[0].email, user_1.email);
}

#[tokio::test]
async fn af_cloud_leave_workspace_test() {
  user_localhost_af_cloud().await;
  let test_1 = EventIntegrationTest::new().await;
  let workspace_id_1 = test_1.get_current_workspace().await.id;

  let test_2 = EventIntegrationTest::new().await;
  let user_2 = test_2.af_cloud_sign_up().await;

  test_1.add_workspace_member(&workspace_id_1, &test_2).await;

  // test_2 should have 2 workspace
  let workspaces = get_synced_workspaces(&test_2, user_2.id).await;
  assert_eq!(workspaces.len(), 2);

  // user_2 leaves the workspace
  test_2.leave_workspace(&workspace_id_1).await;

  // user_2 should have 1 workspace
  let workspaces = get_synced_workspaces(&test_2, user_2.id).await;
  assert_eq!(workspaces.len(), 1);
}
