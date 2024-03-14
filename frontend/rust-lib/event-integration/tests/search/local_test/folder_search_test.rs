use collab_folder::View;
use event_integration::EventIntegrationTest;
use flowy_folder::entities::UpdateViewPayloadPB;
use flowy_folder_pub::folder_builder::{FlattedViews, WorkspaceViewBuilder};
use flowy_search::services::manager::SearchHandler;
use std::time::Duration;
use tokio::time::sleep;

#[tokio::test]
async fn test_folder_index_all_startup() {
  let test = EventIntegrationTest::new_anon().await;
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
}
#[tokio::test]
async fn test_folder_index_create_100_views() {
  let test = EventIntegrationTest::new_anon().await;
  let folder_search_manager = test.get_folder_search_handler();

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;
  let workspace_id = test.get_current_workspace().await.id;

  for i in 0..99 {
    let view = test.create_view(&workspace_id, format!("View {}", i)).await;
    sleep(Duration::from_millis(500)).await;
    assert_eq!(view.name, format!("View {}", i));
  }

  // Wait for the index update to finish
  sleep(Duration::from_millis(1000)).await;

  let num_docs = folder_search_manager.index_count();
  // Workspace + 100 Views
  assert_eq!(num_docs, 101);
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

  let results = folder_search_manager.perform_search(view.name.clone());
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

  let first = folder_search_manager.perform_search(view.name);
  if let Err(e) = first {
    panic!("Error performing search: {:?}", e);
  }

  let second = folder_search_manager.perform_search(new_view_name.clone());
  if let Err(e) = second {
    panic!("Error performing search: {:?}", e);
  }

  let first = first.unwrap();
  assert_eq!(first.len(), 0);

  let second = second.unwrap();
  assert_eq!(second.len(), 1);
  assert_eq!(second[0].data, new_view_name);
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
  let mut builder = WorkspaceViewBuilder::new(workspace_id.clone(), uid);
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
