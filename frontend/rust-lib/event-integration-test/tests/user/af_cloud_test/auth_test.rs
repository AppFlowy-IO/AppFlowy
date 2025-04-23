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

#[tokio::test]
async fn af_cloud_sign_up_then_switch_to_anon_test() {
  // user_localhost_af_cloud_with_nginx().await;
  use_localhost_af_cloud().await;
  let mut test = EventIntegrationTest::new().await;
  test.skip_auto_remove_temp_dir();

  let email = generate_test_email();
  let user = test.af_cloud_sign_in_with_email(&email).await.unwrap();
  assert_eq!(user.email, email);
  test.sign_out().await;
  let config = test.config.clone();
  drop(test);

  let mut test = EventIntegrationTest::new_with_config(config.clone()).await;
  test.skip_auto_remove_temp_dir();
  test.sign_up_as_anon().await;
  drop(test);

  let mut test = EventIntegrationTest::new_with_config(config.clone()).await;
  test.skip_auto_remove_temp_dir();
  let user = test.af_cloud_sign_in_with_email(&email).await.unwrap();
  assert_eq!(user.email, email);
  test.sign_out().await;
  drop(test);

  let mut test = EventIntegrationTest::new_with_config(config).await;
  test.skip_auto_remove_temp_dir();
  test.sign_up_as_anon().await;
}
