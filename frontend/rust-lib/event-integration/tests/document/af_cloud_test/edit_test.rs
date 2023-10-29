use std::time::Duration;

use event_integration::document_event::assert_document_data_equal;
use flowy_document2::entities::DocumentSyncStatePB;

use crate::document::af_cloud_test::util::AFCloudDocumentTest;
use crate::util::receive_with_timeout;

#[tokio::test]
async fn af_cloud_edit_document_test() {
  if let Some(test) = AFCloudDocumentTest::new().await {
    let document_id = test.create_document().await;
    let cloned_test = test.clone();
    let cloned_document_id = document_id.clone();
    test.inner.dispatcher().spawn(async move {
      cloned_test
        .insert_document_text(&cloned_document_id, "hello world", 0)
        .await;
    });

    // wait all update are send to the remote
    let rx = test
      .notification_sender
      .subscribe_with_condition::<DocumentSyncStatePB, _>(&document_id, |pb| pb.is_finish);
    receive_with_timeout(rx, Duration::from_secs(15))
      .await
      .unwrap();

    let document_data = test.get_document_data(&document_id).await;
    let update = test.get_document_update(&document_id).await;
    assert!(!update.is_empty());
    assert_document_data_equal(&update, &document_id, document_data);
  }
}
