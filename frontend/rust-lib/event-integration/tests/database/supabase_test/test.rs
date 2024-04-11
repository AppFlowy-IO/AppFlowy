use std::time::Duration;

use flowy_database2::entities::{
  DatabaseSnapshotStatePB, DatabaseSyncState, DatabaseSyncStatePB, FieldChangesetPB, FieldType,
};
use flowy_database2::notification::DatabaseNotification::DidUpdateDatabaseSnapshotState;

use crate::database::supabase_test::helper::{
  assert_database_collab_content, FlowySupabaseDatabaseTest,
};
use crate::util::receive_with_timeout;

#[tokio::test]
async fn supabase_initial_database_snapshot_test() {
  if let Some(test) = FlowySupabaseDatabaseTest::new_with_new_user().await {
    let (view, database) = test.create_database().await;
    let rx = test
      .notification_sender
      .subscribe::<DatabaseSnapshotStatePB>(&database.id, DidUpdateDatabaseSnapshotState);

    receive_with_timeout(rx, Duration::from_secs(30))
      .await
      .unwrap();

    let expected = test.get_collab_json(&database.id).await;
    let snapshots = test.get_database_snapshots(&view.id).await;
    assert_eq!(snapshots.items.len(), 1);
    assert_database_collab_content(&database.id, &snapshots.items[0].data, expected);
  }
}

#[tokio::test]
async fn supabase_edit_database_test() {
  if let Some(test) = FlowySupabaseDatabaseTest::new_with_new_user().await {
    let (view, database) = test.create_database().await;
    let existing_fields = test.get_all_database_fields(&view.id).await;
    for field in existing_fields.items {
      if !field.is_primary {
        test.delete_field(&view.id, &field.id).await;
      }
    }

    let field = test.create_field(&view.id, FieldType::Checklist).await;
    test
      .update_field(FieldChangesetPB {
        field_id: field.id.clone(),
        view_id: view.id.clone(),
        name: Some("hello world".to_string()),
        ..Default::default()
      })
      .await;

    // wait all updates are send to the remote
    let rx = test
      .notification_sender
      .subscribe_with_condition::<DatabaseSyncStatePB, _>(&database.id, |pb| {
        pb.value == DatabaseSyncState::SyncFinished
      });
    receive_with_timeout(rx, Duration::from_secs(30))
      .await
      .unwrap();

    assert_eq!(test.get_all_database_fields(&view.id).await.items.len(), 2);
    let expected = test.get_collab_json(&database.id).await;
    let update = test.get_database_collab_update(&database.id).await;
    assert_database_collab_content(&database.id, &update, expected);
  }
}

// #[tokio::test]
// async fn cloud_test_supabase_login_sync_database_test() {
//   if let Some(test) = FlowySupabaseDatabaseTest::new_with_new_user().await {
//     let uuid = test.uuid.clone();
//     let (view, database) = test.create_database().await;
//     // wait all updates are send to the remote
//     let mut rx = test
//       .notification_sender
//       .subscribe_with_condition::<DatabaseSyncStatePB, _>(&database.id, |pb| pb.is_finish);
//     receive_with_timeout(&mut rx, Duration::from_secs(30))
//       .await
//       .unwrap();
//     let expected = test.get_collab_json(&database.id).await;
//     test.sign_out().await;
//     // Drop the test will cause the test resources to be dropped, which will
//     // delete the user data folder.
//     drop(test);
//
//     let new_test = FlowySupabaseDatabaseTest::new_with_user(uuid)
//       .await
//       .unwrap();
//     // let actual = new_test.get_collab_json(&database.id).await;
//     // assert_json_eq!(actual, json!(""));
//
//     new_test.open_database(&view.id).await;
//
//     // wait all updates are synced from the remote
//     let mut rx = new_test
//       .notification_sender
//       .subscribe_with_condition::<DatabaseSyncStatePB, _>(&database.id, |pb| pb.is_finish);
//     receive_with_timeout(&mut rx, Duration::from_secs(30))
//       .await
//       .unwrap();
//
//     // when the new sync is finished, the database should be the same as the old one
//     let actual = new_test.get_collab_json(&database.id).await;
//     assert_json_eq!(actual, expected);
//   }
// }
