use event_integration::user_event::{login_password, unique_email};
use event_integration::{event_builder::EventBuilder, EventIntegrationTest};
use flowy_user::entities::{AuthTypePB, SignInPayloadPB, SignUpPayloadPB};
use flowy_user::errors::ErrorCode;
use flowy_user::event_map::UserEvent::*;

use crate::user::local_test::helper::*;

#[tokio::test]
async fn sign_up_with_invalid_email() {
  for email in invalid_email_test_case() {
    let sdk = EventIntegrationTest::new().await;
    let request = SignUpPayloadPB {
      email: email.to_string(),
      name: valid_name(),
      password: login_password(),
      auth_type: AuthTypePB::Local,
      device_id: "".to_string(),
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
      ErrorCode::EmailFormatInvalid
    );
  }
}
#[tokio::test]
async fn sign_up_with_long_password() {
  let sdk = EventIntegrationTest::new().await;
  let request = SignUpPayloadPB {
    email: unique_email(),
    name: valid_name(),
    password: "1234".repeat(100).as_str().to_string(),
    auth_type: AuthTypePB::Local,
    device_id: "".to_string(),
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
    ErrorCode::PasswordTooLong
  );
}

#[tokio::test]
async fn sign_in_with_invalid_email() {
  for email in invalid_email_test_case() {
    let sdk = EventIntegrationTest::new().await;
    let request = SignInPayloadPB {
      email: email.to_string(),
      password: login_password(),
      name: "".to_string(),
      auth_type: AuthTypePB::Local,
      device_id: "".to_string(),
    };

    assert_eq!(
      EventBuilder::new(sdk)
        .event(SignInWithEmailPassword)
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
async fn sign_in_with_invalid_password() {
  for password in invalid_password_test_case() {
    let sdk = EventIntegrationTest::new().await;

    let request = SignInPayloadPB {
      email: unique_email(),
      password,
      name: "".to_string(),
      auth_type: AuthTypePB::Local,
      device_id: "".to_string(),
    };

    assert!(EventBuilder::new(sdk)
      .event(SignInWithEmailPassword)
      .payload(request)
      .async_send()
      .await
      .error()
      .is_some())
  }
}
