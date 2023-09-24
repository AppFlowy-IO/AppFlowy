use std::time::Duration;

use flowy_document2::entities::DocumentSyncStatePB;

use crate::document::af_cloud_test::util::AFCloudDocumentTest;
use crate::util::receive_with_timeout;

#[tokio::test]
async fn af_cloud_sign_up_test() {
  if let Some(test) = AFCloudDocumentTest::new().await {
    let document_id = test.create_document().await;
    test.insert_text(&document_id, "hello world").await;

    // wait all update are send to the remote
    let mut rx = test
      .notification_sender
      .subscribe_with_condition::<DocumentSyncStatePB, _>(&document_id, |pb| pb.is_finish);
    receive_with_timeout(&mut rx, Duration::from_secs(30))
      .await
      .unwrap();

    // let document_data = test.get_document_data(&document_id).await;
    // let update = test.get_collab_update(&document_id).await;
    // assert_document_data_equal(&update, &document_id, document_data);
  }
}
