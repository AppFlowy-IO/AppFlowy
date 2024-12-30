use crate::util::{unzip_test_asset, zip};
use collab_folder::View;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_folder::entities::UpdateViewPayloadPB;
use flowy_folder_pub::folder_builder::{FlattedViews, NestedViewBuilder};
use std::time::Duration;
use tokio::time::sleep;

#[tokio::test]
async fn test_folder_index_all_startup() {
  let folder_name = "folder_1000_view";
  // comment out the following line to create a test asset if you modify the test data
  // don't forget to delete unnecessary test assets
  // create_folder_test_data(folder_name).await;

  let (cleaner, user_db_path) = unzip_test_asset(folder_name).unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path.clone(), DEFAULT_NAME.to_string())
      .await;

  let first_level_views = test.get_all_workspace_views().await;
  assert_eq!(first_level_views.len(), 3);
  assert_eq!(first_level_views[1].name, "1");
  assert_eq!(first_level_views[2].name, "2");

  let view_1 = test.get_view(&first_level_views[1].id).await;
  assert_eq!(view_1.child_views.len(), 500);

  let folder_data = test.get_folder_data();
  // Get started + 1002 Views
  assert_eq!(folder_data.views.len(), 1003);

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;

  let folder_search_manager = test.get_folder_search_handler();
  let num_docs = folder_search_manager.index_count();
  assert_eq!(num_docs, 1004);

  drop(cleaner);
}

#[tokio::test]
async fn test_folder_index_create_20_views() {
  let test = EventIntegrationTest::new_anon().await;
  let folder_search_manager = test.get_folder_search_handler();

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;
  let workspace_id = test.get_current_workspace().await.id;

  for i in 0..20 {
    let view = test.create_view(&workspace_id, format!("View {}", i)).await;
    sleep(Duration::from_millis(500)).await;
    assert_eq!(view.name, format!("View {}", i));
  }

  // Wait for the index update to finish
  sleep(Duration::from_secs(2)).await;

  let num_docs = folder_search_manager.index_count();
  // Workspace + Get started + 20 Views
  assert_eq!(num_docs, 22);
}

#[tokio::test]
async fn test_folder_index_create_view() {
  let test = EventIntegrationTest::new_anon().await;

  let folder_search_manager = test.get_folder_search_handler();

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;

  let workspace_id = test.get_current_workspace().await.id;
  let view = test.create_view(&workspace_id, "Flowers".to_owned()).await;

  // Wait for the index to be updated
  sleep(Duration::from_millis(500)).await;

  let results = folder_search_manager.perform_search(view.name.clone(), None);
  if let Err(e) = results {
    panic!("Error performing search: {:?}", e);
  }

  let results = results.unwrap();
  assert_eq!(results.len(), 1);
  assert_eq!(results[0].data, view.name);
}

#[tokio::test]
async fn test_folder_index_rename_view() {
  let test = EventIntegrationTest::new_anon().await;
  let folder_search_manager = test.get_folder_search_handler();

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;

  let workspace_id = test.get_current_workspace().await.id;
  let view = test.create_view(&workspace_id, "Flowers".to_owned()).await;

  // Wait for the index to be updated
  sleep(Duration::from_millis(500)).await;

  let new_view_name = "Bouquets".to_string();
  let update_payload = UpdateViewPayloadPB {
    view_id: view.id,
    name: Some(new_view_name.clone()),
    ..Default::default()
  };
  test.update_view(update_payload).await;

  // Wait for the index to be updated
  sleep(Duration::from_millis(500)).await;

  let first = folder_search_manager.perform_search(view.name, None);
  if let Err(e) = first {
    panic!("Error performing search: {:?}", e);
  }

  let second = folder_search_manager.perform_search(new_view_name.clone(), None);
  if let Err(e) = second {
    panic!("Error performing search: {:?}", e);
  }

  let first = first.unwrap();
  assert_eq!(first.len(), 0);

  let second = second.unwrap();
  assert_eq!(second.len(), 1);
  assert_eq!(second[0].data, new_view_name);
}

/// Using this method to create a folder test asset. Only use when you want to create a new asset.
/// The file will be created at tests/asset/{file_name}.zip and it will be committed to the repo.
///
#[allow(dead_code)]
async fn create_folder_test_data(file_name: &str) {
  let test = EventIntegrationTest::new_with_name(DEFAULT_NAME).await;
  test.sign_up_as_anon().await;

  let uid = test.get_user_profile().await.unwrap().id;
  let workspace_id = test.get_current_workspace().await.id;
  let views = create_1002_views(uid, workspace_id.clone()).await;
  test.create_views(views).await;

  let first_level_views = test.get_all_workspace_views().await;
  assert_eq!(first_level_views.len(), 3);
  assert_eq!(first_level_views[1].name, "1");
  assert_eq!(first_level_views[2].name, "2");

  let view_1 = test.get_view(&first_level_views[1].id).await;
  assert_eq!(view_1.child_views.len(), 500);

  let folder_data = test.get_folder_data();
  // Get started + 1002 Views
  assert_eq!(folder_data.views.len(), 1003);

  let data_path = test.config.application_path.clone();
  zip(
    data_path.into(),
    format!("tests/asset/{}.zip", file_name).into(),
  )
  .unwrap();
  sleep(Duration::from_secs(2)).await;
}

/// Create view without create the view's content(document/database).
/// workspace
/// - get_started
/// - view_1
///   - view_1_1
///   - view_1_2
/// - view_2
///   - view_2_1
///   - view_2_2
async fn create_1002_views(uid: i64, workspace_id: String) -> Vec<View> {
  let mut builder = NestedViewBuilder::new(workspace_id.clone(), uid);
  builder
    .with_view_builder(|view_builder| async {
      let mut builder = view_builder.with_name("1");
      for i in 0..500 {
        builder = builder
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder.with_name(format!("1_{}", i)).build()
          })
          .await;
      }
      builder.build()
    })
    .await;
  builder
    .with_view_builder(|view_builder| async {
      let mut builder = view_builder.with_name("2");
      for i in 0..500 {
        builder = builder
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder.with_name(format!("2_{}", i)).build()
          })
          .await;
      }
      builder.build()
    })
    .await;
  // The output views should be:
  // view_1
  //   view_1_1
  //   view_1_x
  // view_2
  //   view_2_1
  //   view_2_x
  let views = builder.build();
  FlattedViews::flatten_views(views)
}
