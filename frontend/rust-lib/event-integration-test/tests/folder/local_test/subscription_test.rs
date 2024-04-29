use std::time::Duration;

use event_integration_test::EventIntegrationTest;
use flowy_folder::entities::{ChildViewUpdatePB, RepeatedViewPB, UpdateViewPayloadPB};
use flowy_folder::notification::FolderNotification;

use crate::util::receive_with_timeout;

#[tokio::test]
/// The primary purpose of this test is to validate that the notification subscription mechanism
/// correctly notifies the subscriber of updates to workspace views.
/// 1. Initialize the `FlowyCoreTest` with a guest user.
/// 2. Retrieve the current workspace for the test user.
/// 3. Subscribe to workspace view updates using the `RepeatedViewPB` notification.
/// 4. Spawn a new asynchronous task to create a new view named "test_view" within the workspace.
/// 5. Await the notification for workspace view updates with a timeout of 30 seconds.
/// 6. Ensure that the received views contain the newly created "test_view".
async fn create_child_view_in_workspace_subscription_test() {
  let test = EventIntegrationTest::new_anon().await;
  let workspace = test.get_current_workspace().await;
  let rx = test
    .notification_sender
    .subscribe::<RepeatedViewPB>(&workspace.id, FolderNotification::DidUpdateWorkspaceViews);

  let cloned_test = test.clone();
  let cloned_workspace_id = workspace.id.clone();
  test.appflowy_core.dispatcher().spawn(async move {
    cloned_test
      .create_view(&cloned_workspace_id, "workspace child view".to_string())
      .await;
  });

  let views = receive_with_timeout(rx, Duration::from_secs(30))
    .await
    .unwrap()
    .items;
  assert_eq!(views.len(), 2);
  assert_eq!(views[1].name, "workspace child view".to_string());
}

#[tokio::test]
async fn create_child_view_in_view_subscription_test() {
  let test = EventIntegrationTest::new_anon().await;
  let mut workspace = test.get_current_workspace().await;
  let workspace_child_view = workspace.views.pop().unwrap();
  let rx = test.notification_sender.subscribe::<ChildViewUpdatePB>(
    &workspace_child_view.id,
    FolderNotification::DidUpdateChildViews,
  );

  let cloned_test = test.clone();
  let child_view_id = workspace_child_view.id.clone();
  test.appflowy_core.dispatcher().spawn(async move {
    cloned_test
      .create_view(
        &child_view_id,
        "workspace child view's child view".to_string(),
      )
      .await;
  });

  let update = receive_with_timeout(rx, Duration::from_secs(30))
    .await
    .unwrap();

  assert_eq!(update.create_child_views.len(), 1);
  assert_eq!(
    update.create_child_views[0].name,
    "workspace child view's child view".to_string()
  );
}

#[tokio::test]
async fn delete_view_subscription_test() {
  let test = EventIntegrationTest::new_anon().await;
  let workspace = test.get_current_workspace().await;
  let rx = test
    .notification_sender
    .subscribe::<ChildViewUpdatePB>(&workspace.id, FolderNotification::DidUpdateChildViews);

  let cloned_test = test.clone();
  let delete_view_id = workspace.views.first().unwrap().id.clone();
  let cloned_delete_view_id = delete_view_id.clone();
  test
    .appflowy_core
    .dispatcher()
    .spawn(async move {
      cloned_test.delete_view(&cloned_delete_view_id).await;
    })
    .await
    .unwrap();

  let update = test
    .appflowy_core
    .dispatcher()
    .run_until(receive_with_timeout(rx, Duration::from_secs(30)))
    .await
    .unwrap();

  assert_eq!(update.delete_child_views.len(), 1);
  assert_eq!(update.delete_child_views[0], delete_view_id);
}

#[tokio::test]
async fn update_view_subscription_test() {
  let test = EventIntegrationTest::new_anon().await;
  let mut workspace = test.get_current_workspace().await;
  let rx = test
    .notification_sender
    .subscribe::<ChildViewUpdatePB>(&workspace.id, FolderNotification::DidUpdateChildViews);

  let cloned_test = test.clone();
  let view = workspace.views.pop().unwrap();
  assert!(!view.is_favorite);

  let update_view_id = view.id.clone();
  test.appflowy_core.dispatcher().spawn(async move {
    cloned_test
      .update_view(UpdateViewPayloadPB {
        view_id: update_view_id,
        name: Some("hello world".to_string()),
        is_favorite: Some(true),
        ..Default::default()
      })
      .await;
  });

  let update = receive_with_timeout(rx, Duration::from_secs(30))
    .await
    .unwrap();
  assert_eq!(update.update_child_views.len(), 1);
  let expected_view = update.update_child_views.first().unwrap();
  assert_eq!(expected_view.id, view.id);
  assert_eq!(expected_view.name, "hello world".to_string());
  assert!(expected_view.is_favorite);
}
