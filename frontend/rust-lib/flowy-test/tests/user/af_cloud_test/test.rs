use flowy_test::FlowyCoreTest;

use crate::util::{generate_test_email, get_af_cloud_config};

#[tokio::test]
async fn af_cloud_sign_up_test() {
  if get_af_cloud_config().is_some() {
    let test = FlowyCoreTest::new();
    let email = generate_test_email();
    let user = test.af_cloud_sign_in_with_email(&email).await.unwrap();
    assert_eq!(user.email, email);
  }
}
