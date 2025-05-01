use crate::util::unzip;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_search::services::manager::SearchType;
use futures::StreamExt;
#[tokio::test]
async fn open_089_anon_user_data_folder_test() {
  // Almost same as af_cloud_open_089_anon_user_data_folder_test but doesn't use af_cloud as the backend
  let user_db_path = unzip("./tests/asset", "090_anon_search").unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;
  let workspace_id = test.get_workspace_id().await;
  let search_handler = test
    .search_manager
    .get_handler(SearchType::DocumentLocal)
    .unwrap();

  // Assume after 30 seconds, the indexing is done
  tokio::time::sleep(std::time::Duration::from_secs(30)).await;

  // test search page title
  let stream = search_handler
    .perform_search("japan".to_string(), &workspace_id)
    .await;
  let result = stream.collect::<Vec<_>>().await;
  let local = result[0]
    .as_ref()
    .unwrap()
    .local_search_result
    .as_ref()
    .expect("expected a local_search_result");

  assert_eq!(local.items.len(), 2);
  assert_eq!(local.items[0].display_name, "Japan Skiing");
  assert_eq!(local.items[1].display_name, "Japan Food");

  // test search page content
  let stream = search_handler
    .perform_search("Niseko".to_string(), &workspace_id)
    .await;
  let result = stream.collect::<Vec<_>>().await;
  let local = result[0]
    .as_ref()
    .unwrap()
    .local_search_result
    .as_ref()
    .expect("expected a local_search_result");

  assert_eq!(local.items.len(), 1);
  assert_eq!(local.items[0].display_name, "Japan Skiing");
  dbg!(result);

  // test create a new page then search
  let view = test
    .create_and_open_document(&workspace_id.to_string(), "My dog".to_string(), vec![])
    .await;
  test
    .insert_document_text(&view.id, "I have maltese dog", 0)
    .await;
  test
    .insert_document_text(&view.id, "He loves eating food", 1)
    .await;

  // Assume after 20 seconds, the indexing is done
  tokio::time::sleep(std::time::Duration::from_secs(20)).await;
  let stream = search_handler
    .perform_search("maltese".to_string(), &workspace_id)
    .await;
  let result = stream.collect::<Vec<_>>().await;
  dbg!(&result);

  let local = result[0]
    .as_ref()
    .unwrap()
    .local_search_result
    .as_ref()
    .expect("expected a local_search_result");

  assert_eq!(local.items.len(), 1);
  assert_eq!(local.items[0].display_name, "My dog");
}
