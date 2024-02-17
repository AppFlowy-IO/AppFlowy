use std::time::Duration;

use assert_json_diff::assert_json_eq;
use serde_json::json;

use flowy_folder::entities::{FolderSnapshotStatePB, FolderSyncStatePB};
use flowy_folder::notification::FolderNotification::DidUpdateFolderSnapshotState;

use crate::folder::supabase_test::helper::{assert_folder_collab_content, FlowySupabaseFolderTest};
use crate::util::{get_folder_data_from_server, receive_with_timeout};

#[tokio::test]
async fn supabase_encrypt_folder_test() {
  if let Some(test) = FlowySupabaseFolderTest::new().await {
    let uid = test.user_manager.user_id().unwrap();
    let secret = test.enable_encryption().await;

    let local_folder_data = test.get_local_folder_data().await;
    let workspace_id = test.get_current_workspace().await.id;
    let remote_folder_data = get_folder_data_from_server(&uid, &workspace_id, Some(secret))
      .await
      .unwrap()
      .unwrap();

    assert_json_eq!(json!(local_folder_data), json!(remote_folder_data));
  }
}

#[tokio::test]
async fn supabase_decrypt_folder_data_test() {
  if let Some(test) = FlowySupabaseFolderTest::new().await {
    let uid = test.user_manager.user_id().unwrap();
    let secret = Some(test.enable_encryption().await);
    let workspace_id = test.get_current_workspace().await.id;
    test
      .create_view(&workspace_id, "encrypt view".to_string())
      .await;

    let rx = test
      .notification_sender
      .subscribe_with_condition::<FolderSyncStatePB, _>(&workspace_id, |pb| pb.is_finish);

    receive_with_timeout(rx, Duration::from_secs(10))
      .await
      .unwrap();
    let folder_data = get_folder_data_from_server(&uid, &workspace_id, secret)
      .await
      .unwrap()
      .unwrap();
    assert_eq!(folder_data.views.len(), 2);
    assert_eq!(folder_data.views[1].name, "encrypt view");
  }
}

#[tokio::test]
#[should_panic]
async fn supabase_decrypt_with_invalid_secret_folder_data_test() {
  if let Some(test) = FlowySupabaseFolderTest::new().await {
    let uid = test.user_manager.user_id().unwrap();
    let _ = Some(test.enable_encryption().await);
    let workspace_id = test.get_current_workspace().await.id;
    test
      .create_view(&workspace_id, "encrypt view".to_string())
      .await;
    let rx = test
      .notification_sender
      .subscribe_with_condition::<FolderSyncStatePB, _>(&workspace_id, |pb| pb.is_finish);
    receive_with_timeout(rx, Duration::from_secs(10))
      .await
      .unwrap();

    let _ = get_folder_data_from_server(&uid, &workspace_id, Some("invalid secret".to_string()))
      .await
      .unwrap();
  }
}
#[tokio::test]
async fn supabase_folder_snapshot_test() {
  if let Some(test) = FlowySupabaseFolderTest::new().await {
    let workspace_id = test.get_current_workspace().await.id;
    let rx = test
      .notification_sender
      .subscribe::<FolderSnapshotStatePB>(&workspace_id, DidUpdateFolderSnapshotState);
    receive_with_timeout(rx, Duration::from_secs(10))
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
    let workspace_id = test.get_current_workspace().await.id;

    test
      .create_view(&workspace_id, "supabase test view1".to_string())
      .await;
    test
      .create_view(&workspace_id, "supabase test view2".to_string())
      .await;
    test
      .create_view(&workspace_id, "supabase test view3".to_string())
      .await;

    let rx = test
      .notification_sender
      .subscribe_with_condition::<FolderSyncStatePB, _>(&workspace_id, |pb| pb.is_finish);

    receive_with_timeout(rx, Duration::from_secs(10))
      .await
      .unwrap();

    let expected = test.get_collab_json().await;
    let update = test.get_collab_update(&workspace_id).await;
    assert_folder_collab_content(&workspace_id, &update, expected);
  }
}
