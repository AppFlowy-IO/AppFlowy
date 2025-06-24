use crate::user::local_test::helper::*;
use event_integration_test::{event_builder::EventBuilder, EventIntegrationTest};
use flowy_user::entities::{AuthTypePB, UpdateUserProfilePayloadPB, UserProfilePB};
use flowy_user::{errors::ErrorCode, event_map::UserEvent::*};
use nanoid::nanoid;
#[tokio::test]
async fn user_profile_get_failed() {
  let sdk = EventIntegrationTest::new().await;
  let result = EventBuilder::new(sdk)
    .event(GetUserProfile)
    .async_send()
    .await
    .error();
  assert!(result.is_some())
}

#[tokio::test]
async fn anon_user_profile_get() {
  let test = EventIntegrationTest::new().await;
  let user_profile = test.init_anon_user().await;
  let user = EventBuilder::new(test.clone())
    .event(GetUserProfile)
    .async_send()
    .await
    .parse_or_panic::<UserProfilePB>();
  assert_eq!(user_profile.id, user.id);
  assert_eq!(user_profile.user_auth_type, AuthTypePB::Local);
}

#[tokio::test]
async fn user_update_with_name() {
  let sdk = EventIntegrationTest::new().await;
  let user = sdk.init_anon_user().await;
  let new_name = "hello_world".to_owned();
  let request = UpdateUserProfilePayloadPB::new(user.id).name(&new_name);
  let _ = EventBuilder::new(sdk.clone())
    .event(UpdateUserProfile)
    .payload(request)
    .async_send()
    .await;

  let user_profile = EventBuilder::new(sdk.clone())
    .event(GetUserProfile)
    .async_send()
    .await
    .parse_or_panic::<UserProfilePB>();

  assert_eq!(user_profile.name, new_name,);
}

#[tokio::test]
async fn anon_user_update_with_email() {
  let sdk = EventIntegrationTest::new().await;
  let user = sdk.init_anon_user().await;
  let new_email = format!("{}@gmail.com", nanoid!(6));
  let request = UpdateUserProfilePayloadPB::new(user.id).email(&new_email);
  let _ = EventBuilder::new(sdk.clone())
    .event(UpdateUserProfile)
    .payload(request)
    .async_send()
    .await;
  let user_profile = EventBuilder::new(sdk.clone())
    .event(GetUserProfile)
    .async_send()
    .await
    .parse_or_panic::<UserProfilePB>();

  // When the user is anonymous, the email is empty no matter what you set
  assert!(user_profile.email.is_empty());
}

#[tokio::test]
async fn user_update_with_invalid_email() {
  let test = EventIntegrationTest::new().await;
  let user = test.init_anon_user().await;
  for email in invalid_email_test_case() {
    let request = UpdateUserProfilePayloadPB::new(user.id).email(&email);
    assert_eq!(
      EventBuilder::new(test.clone())
        .event(UpdateUserProfile)
        .payload(request)
        .async_send()
        .await
        .error()
        .unwrap()
        .code,
      ErrorCode::EmailFormatInvalid
    );
  }
}

#[tokio::test]
async fn user_update_with_invalid_password() {
  let test = EventIntegrationTest::new().await;
  let user = test.init_anon_user().await;
  for password in invalid_password_test_case() {
    let request = UpdateUserProfilePayloadPB::new(user.id).password(&password);

    assert!(EventBuilder::new(test.clone())
      .event(UpdateUserProfile)
      .payload(request)
      .async_send()
      .await
      .error()
      .is_some());
  }
}

#[tokio::test]
async fn user_update_with_invalid_name() {
  let test = EventIntegrationTest::new().await;
  let user = test.init_anon_user().await;
  let request = UpdateUserProfilePayloadPB::new(user.id).name("");
  assert!(EventBuilder::new(test.clone())
    .event(UpdateUserProfile)
    .payload(request)
    .async_send()
    .await
    .error()
    .is_some())
}
