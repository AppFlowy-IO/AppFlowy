use event_integration::EventIntegrationTest;
use flowy_user::entities::UpdateUserProfilePayloadPB;

use crate::util::{generate_test_email, get_af_cloud_config};

#[tokio::test]
async fn af_cloud_sign_up_test() {
  if get_af_cloud_config().is_some() {
    let test = EventIntegrationTest::new();
    let email = generate_test_email();
    let user = test.af_cloud_sign_in_with_email(&email).await.unwrap();
    assert_eq!(user.email, email);
  }
}

#[tokio::test]
async fn af_cloud_update_user_metadata() {
  if get_af_cloud_config().is_some() {
    let test = EventIntegrationTest::new();
    let user = test.af_cloud_sign_up().await;

    let old_profile = test.get_user_profile().await.unwrap();
    assert_eq!(old_profile.openai_key, "".to_string());

    test
      .update_user_profile(UpdateUserProfilePayloadPB {
        id: user.id,
        openai_key: Some("new openai key".to_string()),
        stability_ai_key: Some("new stability ai key".to_string()),
        ..Default::default()
      })
      .await;

    let new_profile = test.get_user_profile().await.unwrap();
    assert_eq!(new_profile.openai_key, "new openai key".to_string());
    assert_eq!(
      new_profile.stability_ai_key,
      "new stability ai key".to_string()
    );
  }
}
