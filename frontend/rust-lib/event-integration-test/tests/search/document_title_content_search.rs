use crate::util::unzip;
use event_integration_test::EventIntegrationTest;
use flowy_core::DEFAULT_NAME;
use flowy_search::entities::SearchResponsePB;
use flowy_search::services::manager::SearchType;
use flowy_user::errors::FlowyResult;
use flowy_user_pub::entities::WorkspaceType;
use futures::StreamExt;
use std::time::{Duration, Instant};
use uuid::Uuid;

// Helper function to wait for search indexing to complete
async fn wait_for_indexing(test: &EventIntegrationTest) {
  let mut rx = test
    .user_manager
    .app_life_cycle
    .read()
    .await
    .subscribe_full_indexed_finish()
    .unwrap();
  let _ = rx.changed().await;
}

// Helper function to perform search and collect results
async fn perform_search(
  test: &EventIntegrationTest,
  query: &str,
  workspace_id: &Uuid,
) -> Vec<FlowyResult<SearchResponsePB>> {
  let search_handler = test
    .search_manager
    .get_handler(SearchType::DocumentLocal)
    .unwrap();

  let stream = search_handler
    .perform_search(query.to_string(), workspace_id)
    .await;

  stream.collect().await
}

// Helper function to wait for document to be indexed with a specified query
async fn wait_for_document_indexing(
  test: &EventIntegrationTest,
  query: &str,
  workspace_id: &Uuid,
  document_name: &str,
  timeout_secs: u64,
) -> Vec<FlowyResult<SearchResponsePB>> {
  let start_time = Instant::now();
  let timeout = Duration::from_secs(timeout_secs);
  let mut result = Vec::new();

  while start_time.elapsed() < timeout {
    result = perform_search(test, query, workspace_id).await;

    if let Some(Ok(search_result)) = result.first() {
      if let Some(local) = &search_result.local_search_result {
        if local
          .items
          .iter()
          .any(|item| item.display_name.contains(document_name))
        {
          break;
        }
      }
    }

    tokio::time::sleep(Duration::from_secs(2)).await;
  }

  result
}

#[tokio::test]
async fn anon_user_multiple_workspace_search_test() {
  // SETUP: Initialize test environment with test data
  let user_db_path = unzip("./tests/asset", "090_anon_search").unwrap();
  let test =
    EventIntegrationTest::new_with_user_data_path(user_db_path, DEFAULT_NAME.to_string()).await;
  let first_workspace_id = test.get_workspace_id().await;

  // Wait for initial indexing to complete
  wait_for_indexing(&test).await;
  // TEST CASE 1: Search by page title
  let result = perform_search(&test, "japan", &first_workspace_id).await;
  let local = result[0]
    .as_ref()
    .unwrap()
    .local_search_result
    .as_ref()
    .expect("expected a local_search_result");

  assert_eq!(
    local.items.len(),
    2,
    "Should find 2 pages with 'japan' in the title"
  );
  assert_eq!(
    local.items[0].display_name, "Japan Skiing",
    "First result should be 'Japan Skiing'"
  );
  assert_eq!(
    local.items[1].display_name, "Japan Food",
    "Second result should be 'Japan Food'"
  );

  // TEST CASE 2: Search by page content
  let result = perform_search(&test, "Niseko", &first_workspace_id).await;
  let local = result[0]
    .as_ref()
    .unwrap()
    .local_search_result
    .as_ref()
    .expect("expected a local_search_result");

  assert_eq!(
    local.items.len(),
    1,
    "Should find 1 page with 'Niseko' in the content"
  );
  assert_eq!(
    local.items[0].display_name, "Japan Skiing",
    "The page should be 'Japan Skiing'"
  );

  // TEST CASE 3: Create a new document and verify it becomes searchable
  // Create and add content to new document
  let document_title = "My dog";
  let view = test
    .create_and_open_document(
      &first_workspace_id.to_string(),
      document_title.to_string(),
      vec![],
    )
    .await;
  test
    .insert_document_text(
      &view.id,
      "I have maltese dog, he love eating food all the time",
      0,
    )
    .await;

  // Wait for document to be indexed and searchable
  let result = wait_for_document_indexing(
    &test,
    "maltese dog",
    &first_workspace_id,
    document_title,
    30,
  )
  .await;

  let local = result[0]
    .as_ref()
    .unwrap()
    .local_search_result
    .as_ref()
    .expect("expected a local_search_result");

  assert!(
    local
      .items
      .iter()
      .any(|item| item.display_name.contains(document_title)),
    "New document should be found when searching for its content"
  );

  // TEST CASE 4: Create and search in a second workspace
  // Create and open a new workspace
  let second_workspace_id = Uuid::parse_str(
    &test
      .create_workspace("my second workspace", WorkspaceType::Local)
      .await
      .workspace_id,
  )
  .unwrap();

  test
    .open_workspace(
      &second_workspace_id.to_string(),
      WorkspaceType::Local.into(),
    )
    .await;

  // Wait for indexing in the new workspace
  wait_for_indexing(&test).await;

  // Search in second workspace
  let result = perform_search(&test, "japan", &second_workspace_id).await;
  assert!(
    result[0].as_ref().unwrap().local_search_result.is_none(),
    "Empty workspace should not have results for 'japan'"
  );

  // TEST CASE 5: Return to first workspace and verify search still works
  test
    .open_workspace(&first_workspace_id.to_string(), WorkspaceType::Local.into())
    .await;
  wait_for_indexing(&test).await;
  let result = perform_search(&test, "japan", &first_workspace_id).await;
  assert!(
    !result.is_empty(),
    "First workspace should still have search results after switching workspaces"
  );
}
