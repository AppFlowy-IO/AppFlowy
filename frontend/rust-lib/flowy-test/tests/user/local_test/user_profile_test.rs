use crate::user::local_test::helper::*;
use flowy_test::{event_builder::EventBuilder, FlowyCoreTest};
use flowy_user::entities::{UpdateUserProfilePayloadPB, UserProfilePB};
use flowy_user::{errors::ErrorCode, event_map::UserEvent::*};
use nanoid::nanoid;

// use serial_test::*;

#[tokio::test]
async fn user_profile_get_failed() {
  let sdk = FlowyCoreTest::new();
  let result = EventBuilder::new(sdk)
    .event(GetUserProfile)
    .async_send()
    .await
    .error();
  assert!(result.is_some())
}

#[tokio::test]
async fn user_profile_get() {
  let test = FlowyCoreTest::new();
  let user_profile = test.init_user().await;
  let user = EventBuilder::new(test.clone())
    .event(GetUserProfile)
    .sync_send()
    .parse::<UserProfilePB>();
  assert_eq!(user_profile, user);
}

#[tokio::test]
async fn user_update_with_name() {
  let sdk = FlowyCoreTest::new();
  let user = sdk.init_user().await;
  let new_name = "hello_world".to_owned();
  let request = UpdateUserProfilePayloadPB::new(user.id).name(&new_name);
  let _ = EventBuilder::new(sdk.clone())
    .event(UpdateUserProfile)
    .payload(request)
    .sync_send();

  let user_profile = EventBuilder::new(sdk.clone())
    .event(GetUserProfile)
    .sync_send()
    .parse::<UserProfilePB>();

  assert_eq!(user_profile.name, new_name,);
}

#[tokio::test]
async fn user_update_with_email() {
  let sdk = FlowyCoreTest::new();
  let user = sdk.init_user().await;
  let new_email = format!("{}@gmail.com", nanoid!(6));
  let request = UpdateUserProfilePayloadPB::new(user.id).email(&new_email);
  let _ = EventBuilder::new(sdk.clone())
    .event(UpdateUserProfile)
    .payload(request)
    .sync_send();
  let user_profile = EventBuilder::new(sdk.clone())
    .event(GetUserProfile)
    .sync_send()
    .parse::<UserProfilePB>();

  assert_eq!(user_profile.email, new_email,);
}

#[tokio::test]
async fn user_update_with_invalid_email() {
  let test = FlowyCoreTest::new();
  let user = test.init_user().await;
  for email in invalid_email_test_case() {
    let request = UpdateUserProfilePayloadPB::new(user.id).email(&email);
    assert_eq!(
      EventBuilder::new(test.clone())
        .event(UpdateUserProfile)
        .payload(request)
        .sync_send()
        .error()
        .unwrap()
        .code,
      ErrorCode::EmailFormatInvalid.value()
    );
  }
}

#[tokio::test]
async fn user_update_with_invalid_password() {
  let test = FlowyCoreTest::new();
  let user = test.init_user().await;
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
  let test = FlowyCoreTest::new();
  let user = test.init_user().await;
  let request = UpdateUserProfilePayloadPB::new(user.id).name("");
  assert!(EventBuilder::new(test.clone())
    .event(UpdateUserProfile)
    .payload(request)
    .sync_send()
    .error()
    .is_some())
}
