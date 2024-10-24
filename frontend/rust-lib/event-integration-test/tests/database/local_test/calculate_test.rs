use crate::util::gen_csv_import_data;
use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;

#[tokio::test]
async fn calculation_integration_test1() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let workspace_id = test.get_current_workspace().await.id;
  let payload = gen_csv_import_data("project&task", &workspace_id);
  let views = test.import_data(payload).await;
}
