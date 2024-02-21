use crate::folder::local_test::script::{create_view, FolderTest};
use collab_folder::ViewLayout;
use std::time::Duration;

#[tokio::test]
async fn create_parent_view_test() {
  let test = FolderTest::new().await;
  let _view = create_view(
    &test.sdk,
    &test.workspace.id,
    "hello",
    "",
    ViewLayout::Document,
  )
  .await;

  // sleep 2 seconds to wait for the view to be indexed
  tokio::time::sleep(Duration::from_secs(2)).await;

  let result_1 = test.sdk.search("hello", None).await.items;
  assert_eq!(result_1.len(), 1);

  let result_2 = test.sdk.search("HELLO", None).await.items;
  assert_eq!(result_2.len(), 1);

  assert_eq!(result_1, result_2);
}

#[tokio::test]
async fn create_parent_view_test2() {
  let test = FolderTest::new().await;
  let _view = create_view(
    &test.sdk,
    &test.workspace.id,
    "hello",
    "",
    ViewLayout::Document,
  )
  .await;

  // sleep 2 seconds to wait for the view to be indexed
  tokio::time::sleep(Duration::from_secs(2)).await;

  let result_1 = test.sdk.search2("hello", None).await.items;
  assert_eq!(result_1.len(), 1);
}
