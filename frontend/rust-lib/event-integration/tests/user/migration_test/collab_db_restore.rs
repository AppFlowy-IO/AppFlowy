use event_integration::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;

use crate::util::unzip_history_user_db;

#[tokio::test]
async fn collab_db_restore_test() {
  let (cleaner, user_db_path) = unzip_history_user_db(
    "./tests/user/migration_test/history_user_db",
    "038_collab_db_corrupt_restore",
  )
  .unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 1);

  drop(cleaner);
}
