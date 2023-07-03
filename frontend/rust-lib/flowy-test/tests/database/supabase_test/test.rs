use flowy_database2::entities::DatabaseSyncStatePB;

use crate::database::supabase_test::helper::FlowySupabaseDatabaseTest;

#[tokio::test]
async fn sync_to_remote_test() {
  if let Some(test) = FlowySupabaseDatabaseTest::new().await {
    let database = test.create_database().await;
    let mut rx = test
      .notification_sender
      .subscribe::<DatabaseSyncStatePB>(&database.id);

    while let Some(state) = rx.recv().await {
      tracing::error!("😄sync state: {:?}", state);
      if state.is_finish {
        break;
      }
    }

    // read the database
  }
}
