use flowy_database2::entities::{DatabaseSnapshotStatePB, DatabaseSyncStatePB};
use std::time::Duration;

use crate::database::supabase_test::helper::FlowySupabaseDatabaseTest;
use crate::util::receive_with_timeout;

#[tokio::test]
async fn initial_collab_update_test() {
  if let Some(test) = FlowySupabaseDatabaseTest::new().await {
    let (view, database) = test.create_database().await;
    let mut rx = test
      .notification_sender
      .subscribe::<DatabaseSnapshotStatePB>(&database.id);

    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    let snapshots = test.get_database_snapshots(&view.id).await;
    assert_eq!(snapshots.items.len(), 1);
  }
}
