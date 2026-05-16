use event_integration_test::document::document_event::DocumentEventTest;
use event_integration_test::document_data_from_document_doc_state;
use std::time::Duration;
use tokio::task::yield_now;

#[tokio::test]
async fn create_document_snapshot_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  for i in 0..1000 {
    test.insert_index(&view.id, &i.to_string(), 1, None).await;
    if i % 10 == 0 {
      yield_now().await;
    }
  }

  // wait for the snapshot to save to disk
  tokio::time::sleep(Duration::from_secs(2)).await;

  let snapshot_metas = test.get_document_snapshot_metas(&view.id).await;
  assert_eq!(snapshot_metas.len(), 1);

  for snapshot_meta in snapshot_metas {
    let data = test.get_document_snapshot(snapshot_meta).await;
    let _ = document_data_from_document_doc_state(&view.id, data.encoded_v1);
  }
}
//
// #[tokio::test]
// async fn maximum_document_snapshot_tests() {
//   let test = DocumentEventTest::new().await;
//   let view = test.create_document().await;
//   for i in 0..8000 {
//     test.insert_index(&view.id, &i.to_string(), 1, None).await;
//     if i % 1000 == 0 {
//       tokio::time::sleep(Duration::from_secs(1)).await;
//     }
//   }
//
//   // wait for the snapshot to save to disk
//   tokio::time::sleep(Duration::from_secs(1)).await;
//   let snapshot_metas = test.get_document_snapshot_metas(&view.id).await;
//   // The default maximum snapshot is 5
//   assert_eq!(snapshot_metas.len(), 5);
// }
