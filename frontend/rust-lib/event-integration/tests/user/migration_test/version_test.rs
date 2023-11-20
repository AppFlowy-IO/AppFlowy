use event_integration::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_folder2::entities::ViewLayoutPB;

use crate::util::unzip_history_user_db;

#[tokio::test]
async fn migrate_020_historical_empty_document_test() {
  let (cleaner, user_db_path) = unzip_history_user_db(
    "./tests/user/migration_test/history_user_db",
    "020_historical_user_data",
  )
  .unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let mut views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 1);

  // Check the parent view
  let parent_view = views.pop().unwrap();
  assert_eq!(parent_view.layout, ViewLayoutPB::Document);
  let data = test.open_document(parent_view.id.clone()).await.data;
  assert!(!data.page_id.is_empty());
  assert_eq!(data.blocks.len(), 2);
  assert!(!data.meta.children_map.is_empty());

  // Check the child views of the parent view
  let child_views = test.get_views(&parent_view.id).await.child_views;
  assert_eq!(child_views.len(), 4);
  assert_eq!(child_views[0].layout, ViewLayoutPB::Document);
  assert_eq!(child_views[1].layout, ViewLayoutPB::Grid);
  assert_eq!(child_views[2].layout, ViewLayoutPB::Calendar);
  assert_eq!(child_views[3].layout, ViewLayoutPB::Board);

  let database = test.get_database(&child_views[1].id).await;
  assert_eq!(database.fields.len(), 8);
  assert_eq!(database.rows.len(), 3);
  drop(cleaner);
}

#[tokio::test]
async fn migrate_036_fav_v1_workspace_array_test() {
  // Used to test migration: FavoriteV1AndWorkspaceArrayMigration
  let (cleaner, user_db_path) = unzip_history_user_db(
    "./tests/user/migration_test/history_user_db",
    "036_fav_v1_workspace_array",
  )
  .unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 2);
  assert_eq!(views[0].name, "root page");
  assert_eq!(views[1].name, "⭐\u{fe0f} Getting started");

  let views = test.get_views(&views[1].id).await;
  assert_eq!(views.child_views.len(), 3);
  assert!(views.child_views[2].is_favorite);
  drop(cleaner);
}
