use flowy_database2::entities::{
  DatabaseSnapshotStatePB, DatabaseSyncStatePB, FieldChangesetPB, FieldType,
};

use std::time::Duration;

use crate::database::supabase_test::helper::{
  assert_database_collab_content, FlowySupabaseDatabaseTest,
};
use crate::util::receive_with_timeout;

#[tokio::test]
async fn supabase_initial_database_snapshot_test() {
  if let Some(test) = FlowySupabaseDatabaseTest::new().await {
    let (view, database) = test.create_database().await;
    let mut rx = test
      .notification_sender
      .subscribe::<DatabaseSnapshotStatePB>(&database.id);

    receive_with_timeout(&mut rx, Duration::from_secs(30))
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
  if let Some(test) = FlowySupabaseDatabaseTest::new().await {
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

    // wait all update is send to the remote
    let mut rx = test
      .notification_sender
      .subscribe_with_condition::<DatabaseSyncStatePB, _>(&database.id, |pb| pb.is_finish);
    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    assert_eq!(test.get_all_database_fields(&view.id).await.items.len(), 2);
    let expected = test.get_collab_json(&database.id).await;
    let update = test.get_collab_update(&database.id).await;
    assert_database_collab_content(&database.id, &update, expected);
  }
}

#[tokio::test]
async fn supabase_login_sync_database_test() {
  if let Some(test) = FlowySupabaseDatabaseTest::new().await {
    let uuid = test.uuid.clone();
    let (view, _database) = test.create_database().await;
    let existing_fields = test.get_all_database_fields(&view.id).await;
    for field in existing_fields.items {
      if !field.is_primary {
        test.delete_field(&view.id, &field.id).await;
      }
    }

    let new_test = FlowySupabaseDatabaseTest::new().await.unwrap();
    new_test.sign_up_with_uuid(&uuid).await;
  }
}
