use flowy_test::user_event::*;
use flowy_test::{event_builder::EventBuilder, FlowyCoreTest};
use flowy_user::entities::{AuthTypePB, SignInPayloadPB, SignUpPayloadPB, UserProfilePB};
use flowy_user::errors::ErrorCode;
use flowy_user::event_map::UserEvent::*;

use crate::user::local_test::helper::*;

#[tokio::test]
async fn sign_up_with_invalid_email() {
  for email in invalid_email_test_case() {
    let sdk = FlowyCoreTest::new();
    let request = SignUpPayloadPB {
      email: email.to_string(),
      name: valid_name(),
      password: login_password(),
      auth_type: AuthTypePB::Local,
    };

    assert_eq!(
      EventBuilder::new(sdk)
        .event(SignUp)
        .payload(request)
        .async_send()
        .await
        .error()
        .unwrap()
        .code,
      ErrorCode::EmailFormatInvalid.value()
    );
  }
}
#[tokio::test]
async fn sign_up_with_long_password() {
  let sdk = FlowyCoreTest::new();
  let request = SignUpPayloadPB {
    email: random_email(),
    name: valid_name(),
    password: "1234".repeat(100).as_str().to_string(),
    auth_type: AuthTypePB::Local,
  };

  assert_eq!(
    EventBuilder::new(sdk)
      .event(SignUp)
      .payload(request)
      .async_send()
      .await
      .error()
      .unwrap()
      .code,
    ErrorCode::PasswordTooLong.value()
  );
}

#[tokio::test]
async fn sign_in_success() {
  let test = FlowyCoreTest::new();
  let _ = EventBuilder::new(test.clone()).event(SignOut).sync_send();
  let sign_up_context = test.sign_up().await;

  let request = SignInPayloadPB {
    email: sign_up_context.user_profile.email.clone(),
    password: sign_up_context.password.clone(),
    name: "".to_string(),
    auth_type: AuthTypePB::Local,
  };

  let response = EventBuilder::new(test.clone())
    .event(SignIn)
    .payload(request)
    .async_send()
    .await
    .parse::<UserProfilePB>();
  dbg!(&response);
}

#[tokio::test]
async fn sign_in_with_invalid_email() {
  for email in invalid_email_test_case() {
    let sdk = FlowyCoreTest::new();
    let request = SignInPayloadPB {
      email: email.to_string(),
      password: login_password(),
      name: "".to_string(),
      auth_type: AuthTypePB::Local,
    };

    assert_eq!(
      EventBuilder::new(sdk)
        .event(SignIn)
        .payload(request)
        .async_send()
        .await
        .error()
        .unwrap()
        .code,
      ErrorCode::EmailFormatInvalid.value()
    );
  }
}

#[tokio::test]
async fn sign_in_with_invalid_password() {
  for password in invalid_password_test_case() {
    let sdk = FlowyCoreTest::new();

    let request = SignInPayloadPB {
      email: random_email(),
      password,
      name: "".to_string(),
      auth_type: AuthTypePB::Local,
    };

    assert!(EventBuilder::new(sdk)
      .event(SignIn)
      .payload(request)
      .async_send()
      .await
      .error()
      .is_some())
  }
}
