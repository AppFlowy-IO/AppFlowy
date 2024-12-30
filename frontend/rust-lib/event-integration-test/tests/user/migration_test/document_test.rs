use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_folder::entities::ViewLayoutPB;

use crate::util::unzip;

#[tokio::test]
async fn migrate_historical_empty_document_test() {
  let user_db_path = unzip(
    "./tests/user/migration_test/history_user_db",
    "historical_empty_document",
  )
  .unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 3);
  for view in views {
    assert_eq!(view.layout, ViewLayoutPB::Document);
    let data = test.open_document(view.id).await.data;
    assert!(!data.page_id.is_empty());
    assert_eq!(data.blocks.len(), 2);
    assert!(!data.meta.children_map.is_empty());
  }
}
