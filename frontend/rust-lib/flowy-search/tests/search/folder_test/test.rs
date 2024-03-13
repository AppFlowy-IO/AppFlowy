use std::time::Duration;

use crate::search::search_manager;
use flowy_folder::entities::UpdateViewPayloadPB;
use flowy_search::{folder::handler::FolderSearchHandler, services::manager::SearchHandler};
use tokio::time::sleep;

#[tokio::test]
async fn test_folder_index_all_startup() {
  // TODO(Mathias): Large folder test with 1000 views
}

#[tokio::test]
async fn test_folder_index_create_100_views() {
  let test = search_manager::SearchManagerTest::new_folder_test().await;

  let folder_search_manager = test
    .sdk
    .search_manager
    .handlers
    .first()
    .unwrap()
    .as_any()
    .downcast_ref::<FolderSearchHandler>()
    .unwrap();

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;

  for i in 0..99 {
    let view = test
      .sdk
      .create_view(&test.view_id, format!("View {}", i))
      .await;
    sleep(Duration::from_millis(500)).await;

    assert_eq!(view.name, format!("View {}", i));
  }

  // Wait for the index update to finish
  sleep(Duration::from_millis(1000)).await;

  let num_docs = folder_search_manager.index_manager.num_docs();

  // Workspace + The Parent View + 100 Views
  assert_eq!(num_docs, 102);
}

#[tokio::test]
async fn test_folder_index_create_view() {
  let test = search_manager::SearchManagerTest::new_folder_test().await;

  let folder_search_manager = test
    .sdk
    .search_manager
    .handlers
    .first()
    .unwrap()
    .as_any()
    .downcast_ref::<FolderSearchHandler>()
    .unwrap();

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;

  let view = test
    .sdk
    .create_view(&test.view_id, "Flowers".to_owned())
    .await;

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
  let test = search_manager::SearchManagerTest::new_folder_test().await;

  let folder_search_manager = test
    .sdk
    .search_manager
    .handlers
    .first()
    .unwrap()
    .as_any()
    .downcast_ref::<FolderSearchHandler>()
    .unwrap();

  // Wait for the index to be created/updated
  sleep(Duration::from_secs(1)).await;

  let view = test
    .sdk
    .create_view(&test.view_id, "Flowers".to_owned())
    .await;

  // Wait for the index to be updated
  sleep(Duration::from_millis(500)).await;

  let new_view_name = "Bouquets".to_string();
  let update_payload = UpdateViewPayloadPB {
    view_id: view.id,
    name: Some(new_view_name.clone()),
    ..Default::default()
  };
  test.sdk.update_view(update_payload).await;

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
