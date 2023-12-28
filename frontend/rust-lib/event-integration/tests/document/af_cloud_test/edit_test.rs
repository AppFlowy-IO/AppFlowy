use std::time::Duration;

use event_integration::document_event::assert_document_data_equal;
use event_integration::user_event::user_localhost_af_cloud;
use event_integration::EventIntegrationTest;
use flowy_document2::entities::DocumentSyncStatePB;

use crate::util::receive_with_timeout;

#[tokio::test]
async fn af_cloud_edit_document_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;
  test.wait_ws_connected().await;

  // create document and then insert content
  let current_workspace = test.get_current_workspace().await;
  let view = test
    .create_and_open_document(&current_workspace.id, "my document".to_string(), vec![])
    .await;
  test.insert_document_text(&view.id, "hello world", 0).await;

  let document_id = view.id;
  println!("document_id: {}", document_id);

  // wait all update are send to the remote
  let rx = test
    .notification_sender
    .subscribe_with_condition::<DocumentSyncStatePB, _>(&document_id, |pb| !pb.is_syncing);
  let _ = receive_with_timeout(rx, Duration::from_secs(30)).await;

  let document_data = test.get_document_data(&document_id).await;
  let doc_state = test.get_document_doc_state(&document_id).await;
  assert!(!doc_state.is_empty());
  assert_document_data_equal(&doc_state, &document_id, document_data);
}
