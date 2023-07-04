use std::time::Duration;

use flowy_document2::entities::DocumentSnapshotStatePB;

use crate::document::supabase_test::helper::{
  assert_document_snapshot_equal, FlowySupabaseDocumentTest,
};
use crate::util::receive_with_timeout;

#[tokio::test]
async fn supabase_initial_document_snapshot_test() {
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
    assert_document_snapshot_equal(&snapshots.items[0], &view.id, document_data);
  }
}
