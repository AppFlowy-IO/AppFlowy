use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;

use crate::util::generate_test_email;

#[tokio::test]
async fn af_cloud_sign_up_test() {
  // user_localhost_af_cloud_with_nginx().await;
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  let email = generate_test_email();
  let user = test.af_cloud_sign_in_with_email(&email).await.unwrap();
  assert_eq!(user.email, email);
}
