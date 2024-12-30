use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_ai::entities::CompletionTypePB;

use std::time::Duration;

#[tokio::test]
async fn af_cloud_complete_text_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;

  let _workspace_id = test.get_current_workspace().await.id;
  let _task = test
    .complete_text("hello world", CompletionTypePB::MakeLonger)
    .await;

  tokio::time::sleep(Duration::from_secs(6)).await;
}
