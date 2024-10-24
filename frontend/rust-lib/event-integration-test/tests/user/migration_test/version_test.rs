use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_folder::entities::ViewLayoutPB;
use std::time::Duration;

use crate::util::unzip;

#[tokio::test]
async fn migrate_020_historical_empty_document_test() {
  let user_db_path = unzip(
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
  let child_views = test.get_view(&parent_view.id).await.child_views;
  assert_eq!(child_views.len(), 4);
  assert_eq!(child_views[0].layout, ViewLayoutPB::Document);
  assert_eq!(child_views[1].layout, ViewLayoutPB::Grid);
  assert_eq!(child_views[2].layout, ViewLayoutPB::Calendar);
  assert_eq!(child_views[3].layout, ViewLayoutPB::Board);

  let database = test.get_database(&child_views[1].id).await;
  assert_eq!(database.fields.len(), 8);
  assert_eq!(database.rows.len(), 3);
}

#[tokio::test]
async fn migrate_036_fav_v1_workspace_array_test() {
  // Used to test migration: FavoriteV1AndWorkspaceArrayMigration
  let user_db_path = unzip(
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

  let views = test.get_view(&views[1].id).await;
  assert_eq!(views.child_views.len(), 3);
  assert!(views.child_views[2].is_favorite);
}

#[tokio::test]
async fn migrate_038_trash_test() {
  // Used to test migration: WorkspaceTrashMapToSectionMigration
  let user_db_path = unzip("./tests/asset", "038_local").unwrap();
  // Getting started
  //  Document1
  //  Document2(deleted)
  //  Document3(deleted)
  // Document
  //  Document4(deleted)
  //  Document5

  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 2);
  assert_eq!(views[0].name, "Getting started");
  assert_eq!(views[1].name, "Documents");

  let get_started_child_views = test.get_view(&views[0].id).await.child_views;
  assert_eq!(get_started_child_views.len(), 1);
  assert_eq!(get_started_child_views[0].name, "Document1");

  let get_started_child_views = test.get_view(&views[1].id).await.child_views;
  assert_eq!(get_started_child_views.len(), 1);
  assert_eq!(get_started_child_views[0].name, "Document5");

  let trash_items = test.get_trash().await.items;
  assert_eq!(trash_items.len(), 3);
  assert_eq!(trash_items[0].name, "Document3");
  assert_eq!(trash_items[1].name, "Document2");
  assert_eq!(trash_items[2].name, "Document4");
}

#[tokio::test]
async fn migrate_038_trash_test2() {
  // Used to test migration: WorkspaceTrashMapToSectionMigration
  let user_db_path = unzip("./tests/asset", "038_document_with_grid").unwrap();
  // Getting started
  //  document
  //    grid
  //      board

  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let views = test.get_all_workspace_views().await;
  assert_eq!(views.len(), 1);
  assert_eq!(views[0].name, "Getting started");

  let views = test.get_view(&views[0].id).await.child_views;
  assert_eq!(views[0].name, "document");

  let views = test.get_view(&views[0].id).await.child_views;
  assert_eq!(views[0].name, "grid");

  let views = test.get_view(&views[0].id).await.child_views;
  assert_eq!(views[0].name, "board");
}

#[tokio::test]
async fn collab_db_backup_test() {
  // Used to test migration: WorkspaceTrashMapToSectionMigration
  let user_db_path = unzip("./tests/asset", "038_local").unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let uid = test.get_user_profile().await.unwrap().id;
  // sleep a bit to make sure the backup is generated

  tokio::time::sleep(Duration::from_secs(10)).await;
  let backups = test.user_manager.get_collab_backup_list(uid);

  assert_eq!(backups.len(), 1);
  assert_eq!(
    backups[0],
    format!("collab_db_{}", chrono::Local::now().format("%Y%m%d"))
  );
}

#[tokio::test]
async fn delete_outdated_collab_db_backup_test() {
  // Used to test migration: WorkspaceTrashMapToSectionMigration
  let user_db_path = unzip("./tests/asset", "040_collab_backups").unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;

  let uid = test.get_user_profile().await.unwrap().id;
  // saving the backup is a background task, so we need to wait for it to finish
  // 2 seconds should be enough for the background task to finish
  tokio::time::sleep(Duration::from_secs(2)).await;
  let backups = test.user_manager.get_collab_backup_list(uid);

  if backups.len() != 10 {
    dbg!("backups: {:?}", backups.clone());
  }

  assert_eq!(backups.len(), 10);
  assert_eq!(backups[0], "collab_db_0.4.0_20231202");
  assert_eq!(backups[1], "collab_db_0.4.0_20231203");
  assert_eq!(backups[2], "collab_db_0.4.0_20231204");
  assert_eq!(backups[3], "collab_db_0.4.0_20231205");
  assert_eq!(backups[4], "collab_db_0.4.0_20231206");
  assert_eq!(backups[5], "collab_db_0.4.0_20231207");
  assert_eq!(backups[6], "collab_db_0.4.0_20231208");
  assert_eq!(backups[7], "collab_db_0.4.0_20231209");
  assert_eq!(backups[8], "collab_db_0.4.0_20231210");
  assert_eq!(
    backups[9],
    format!("collab_db_{}", chrono::Local::now().format("%Y%m%d"))
  );
}
