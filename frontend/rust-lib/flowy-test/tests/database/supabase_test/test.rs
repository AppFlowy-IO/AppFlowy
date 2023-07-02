use std::time::Duration;

use crate::database::supabase_test::helper::FlowySupabaseDatabaseTest;

#[tokio::test]
async fn sync_to_remote_test() {
  if let Some(test) = FlowySupabaseDatabaseTest::new().await {
    let database = test.create_database().await;
    tokio::time::sleep(Duration::from_secs(10)).await;
  }
}
