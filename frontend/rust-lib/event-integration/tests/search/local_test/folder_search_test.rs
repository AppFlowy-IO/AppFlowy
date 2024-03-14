use collab_folder::View;
use event_integration::EventIntegrationTest;
use flowy_folder::entities::UpdateViewPayloadPB;
use flowy_folder_pub::folder_builder::{FlattedViews, WorkspaceViewBuilder};
use flowy_search::folder::handler::FolderSearchHandler;
use flowy_search::services::manager::SearchHandler;
use std::time::Duration;
use tokio::time::sleep;

#[tokio::test]
async fn test_folder_index_all_startup() {
  let test = EventIntegrationTest::new_anon().await;
  let workspace_id = test.get_current_workspace().await.id;
  let views = create_1000_views(workspace_id.clone()).await;
  test.create_views(views);

  let folder_data = test.get_folder_data();
  // Workspace + Get started + 1000 Views
  assert_eq!(folder_data.views.len(), 1002);
}
#[tokio::test]
async fn test_folder_index_create_100_views() {
  let test = EventIntegrationTest::new_anon().await;

  let folder_search_manager = test
    .appflowy_core
    .search_manager
    .handlers
    .first()
    .unwrap()
    .as_any()
    .downcast_ref::<FolderSearchHandler>()
    .unwrap();

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

  let num_docs = folder_search_manager.index_manager.num_docs();

  // Workspace + 100 Views
  assert_eq!(num_docs, 101);
}

#[tokio::test]
async fn test_folder_index_create_view() {
  let test = EventIntegrationTest::new_anon().await;

  let folder_search_manager = test
    .appflowy_core
    .search_manager
    .handlers
    .first()
    .unwrap()
    .as_any()
    .downcast_ref::<FolderSearchHandler>()
    .unwrap();

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

  let folder_search_manager = test
    .appflowy_core
    .search_manager
    .handlers
    .first()
    .unwrap()
    .as_any()
    .downcast_ref::<FolderSearchHandler>()
    .unwrap();

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

async fn create_1000_views(workspace_id: String) -> Vec<View> {
  let mut builder = WorkspaceViewBuilder::new(workspace_id.clone(), 1);
  builder
    .with_view_builder(|view_builder| async {
      let mut builder = view_builder.with_name("1");
      for i in 0..500 {
        builder = builder
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder.with_name(format!("1_1_{}", i)).build()
          })
          .await;
      }

      for i in 0..500 {
        builder = builder
          .with_child_view_builder(|child_view_builder| async {
            child_view_builder.with_name(format!("1_2_{}", i)).build()
          })
          .await;
      }
      builder.build()
    })
    .await;
  let views = builder.build();
  FlattedViews::flatten_views(views)
}
