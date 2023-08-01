use std::time::Duration;

use flowy_folder2::entities::{FolderSnapshotStatePB, FolderSyncStatePB};
use flowy_folder2::notification::FolderNotification::DidUpdateFolderSnapshotState;

use crate::folder::supabase_test::helper::{assert_folder_collab_content, FlowySupabaseFolderTest};
use crate::util::receive_with_timeout;

#[tokio::test]
async fn supabase_initial_folder_snapshot_test() {
  if let Some(test) = FlowySupabaseFolderTest::new().await {
    let workspace_id = test.get_current_workspace().await.workspace.id;
    let mut rx = test
      .notification_sender
      .subscribe::<FolderSnapshotStatePB>(&workspace_id, DidUpdateFolderSnapshotState);

    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    let expected = test.get_collab_json().await;
    let snapshots = test.get_folder_snapshots(&workspace_id).await;
    assert_eq!(snapshots.len(), 1);
    assert_folder_collab_content(&workspace_id, &snapshots[0].data, expected);
  }
}

#[tokio::test]
async fn supabase_initial_folder_snapshot_test2() {
  if let Some(test) = FlowySupabaseFolderTest::new().await {
    let workspace_id = test.get_current_workspace().await.workspace.id;

    test
      .create_view(&workspace_id, "supabase test view1".to_string())
      .await;
    test
      .create_view(&workspace_id, "supabase test view2".to_string())
      .await;
    test
      .create_view(&workspace_id, "supabase test view3".to_string())
      .await;

    let mut rx = test
      .notification_sender
      .subscribe_with_condition::<FolderSyncStatePB, _>(&workspace_id, |pb| pb.is_finish);

    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    let expected = test.get_collab_json().await;
    let update = test.get_collab_update(&workspace_id).await;
    assert_folder_collab_content(&workspace_id, &update, expected);
  }
}
