use std::time::Duration;

use flowy_document2::entities::{DocumentSnapshotPB, DocumentSnapshotStatePB};

use crate::document::supabase_test::helper::FlowySupabaseDocumentTest;

#[tokio::test]
async fn initial_collab_update_test() {
  if let Some(test) = FlowySupabaseDocumentTest::new().await {
    let view = test.create_document().await;

    let mut rx = test
      .notification_sender
      .subscribe::<DocumentSnapshotStatePB>(&view.id);

    // Continue to receive updates until we get the initial snapshot
    loop {
      if let Some(state) = rx.recv().await {
        if let Some(snapshot_id) = state.new_snapshot_id {
          break;
        }
      }
    }

    let snapshots = test.get_document_snapshots(&view.id).await;
    assert_eq!(snapshots.items.len(), 1);
  }
}
