use std::ops::Deref;
use std::time::Duration;

use flowy_document2::entities::{DocumentSnapshotStatePB, DocumentSyncStatePB};
use flowy_test::document::document_event::DocumentEventTest;

use crate::document::supabase_test::helper::{
  assert_document_data_equal, FlowySupabaseDocumentTest,
};
use crate::util::receive_with_timeout;

#[tokio::test]
async fn cloud_test_supabase_initial_document_snapshot_test() {
  if let Some(test) = FlowySupabaseDocumentTest::new().await {
    let view = test.create_document().await;

    let mut rx = test
      .notification_sender
      .subscribe::<DocumentSnapshotStatePB>(&view.id);

    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    let snapshots = test.get_document_snapshots(&view.id).await;
    assert_eq!(snapshots.items.len(), 1);

    let document_data = test.get_document_data(&view.id).await;
    assert_document_data_equal(&snapshots.items[0].data, &view.id, document_data);
  }
}

#[tokio::test]
async fn cloud_test_supabase_document_edit_sync_test() {
  if let Some(test) = FlowySupabaseDocumentTest::new().await {
    let view = test.create_document().await;
    let document_id = view.id.clone();

    let core = test.deref().deref().clone();
    let document_event = DocumentEventTest::new_with_core(core);
    document_event
      .insert_index(&document_id, "hello world", 0, None)
      .await;

    // wait all update are send to the remote
    let mut rx = test
      .notification_sender
      .subscribe_with_condition::<DocumentSyncStatePB, _>(&document_id, |pb| pb.is_finish);
    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    let document_data = test.get_document_data(&document_id).await;
    let update = test.get_collab_update(&document_id).await;
    assert_document_data_equal(&update, &document_id, document_data);
  }
}

#[tokio::test]
async fn cloud_test_supabase_document_edit_sync_test2() {
  if let Some(test) = FlowySupabaseDocumentTest::new().await {
    let view = test.create_document().await;
    let document_id = view.id.clone();
    let core = test.deref().deref().clone();
    let document_event = DocumentEventTest::new_with_core(core);

    for i in 0..10 {
      document_event
        .insert_index(&document_id, "hello world", i, None)
        .await;
    }

    // wait all update are send to the remote
    let mut rx = test
      .notification_sender
      .subscribe_with_condition::<DocumentSyncStatePB, _>(&document_id, |pb| pb.is_finish);
    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    let document_data = test.get_document_data(&document_id).await;
    let update = test.get_collab_update(&document_id).await;
    assert_document_data_equal(&update, &document_id, document_data);
  }
}
