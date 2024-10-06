use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_user::entities::AuthenticatorPB;

use crate::util::unzip;

#[tokio::test]
async fn reading_039_anon_user_data_test() {
  let (cleaner, user_db_path) = unzip("./tests/asset", "039_local").unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;
  let first_level_views = test.get_all_workspace_views().await;
  // In the 039_local, the structure is:
  // workspace:
  //  view: Document1
  //    view: Document2
  //      view: Grid1
  //      view: Grid2
  assert_eq!(first_level_views.len(), 1);
  assert_eq!(
    first_level_views[0].id,
    "50a150e0-2aa9-4131-a259-8ef989315540".to_string()
  );
  assert_eq!(first_level_views[0].name, "Document1".to_string());

  let second_level_views = test.get_view(&first_level_views[0].id).await.child_views;
  assert_eq!(second_level_views.len(), 1);
  assert_eq!(second_level_views[0].name, "Document2".to_string());

  // In the 039_local, there is only one view of the workspaces child
  let third_level_views = test.get_view(&second_level_views[0].id).await.child_views;
  assert_eq!(third_level_views.len(), 2);
  assert_eq!(third_level_views[0].name, "Grid1".to_string());
  assert_eq!(third_level_views[1].name, "Grid2".to_string());

  let trash_items = test.get_trash().await.items;
  assert_eq!(trash_items.len(), 1);

  drop(cleaner);
}

#[tokio::test]
async fn migrate_anon_user_data_to_af_cloud_test() {
  let (cleaner, user_db_path) = unzip("./tests/asset", "040_local").unwrap();
  // In the 040_local, the structure is:
  // workspace:
  //  view: Document1
  //    view: Document2
  //      view: Grid1
  //      view: Grid2
  use_localhost_af_cloud().await;
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path.clone(), DEFAULT_NAME.to_string())
      .await;
  let anon_trash = test.get_trash().await;
  assert_eq!(anon_trash.items.len(), 1);
  assert_eq!(
    anon_trash.items[0].name,
    "Local Getting started".to_string()
  );

  let anon_first_level_views = test.get_all_workspace_views().await;
  let anon_second_level_views = test
    .get_view(&anon_first_level_views[0].id)
    .await
    .child_views;
  let anon_third_level_views = test
    .get_view(&anon_second_level_views[0].id)
    .await
    .child_views;

  // The anon user data will be migrated to the AppFlowy cloud after sign up
  let user = test.af_cloud_sign_up().await;
  let workspace = test.get_current_workspace().await;
  println!("user workspace: {:?}", workspace.id);
  assert_eq!(user.authenticator, AuthenticatorPB::AppFlowyCloud);

  let user_first_level_views = test.get_all_workspace_views().await;
  assert_eq!(user_first_level_views.len(), 3);

  println!("user first level views: {:?}", user_first_level_views);
  let user_second_level_views = test
    .get_view(&user_first_level_views[2].id)
    .await
    .child_views;
  println!("user second level views: {:?}", user_second_level_views);
  let user_third_level_views = test
    .get_view(&user_second_level_views[0].id)
    .await
    .child_views;
  println!("user third level views: {:?}", user_third_level_views);

  // check first level
  assert_eq!(anon_first_level_views.len(), 1);

  // the first view of user_first_level_views is the default get started view
  assert_eq!(user_first_level_views.len(), 3);
  assert_ne!(anon_first_level_views[0].id, user_first_level_views[1].id);
  assert_eq!(
    anon_first_level_views[0].name,
    user_first_level_views[2].name
  );

  // check second level
  assert_ne!(anon_second_level_views[0].id, user_second_level_views[0].id);
  assert_eq!(
    anon_second_level_views[0].name,
    user_second_level_views[0].name
  );

  // check third level
  assert_eq!(anon_third_level_views.len(), 2);
  assert_eq!(user_third_level_views[0].name, "Grid1".to_string());
  assert_eq!(user_third_level_views[1].name, "Grid2".to_string());

  drop(cleaner);
}
