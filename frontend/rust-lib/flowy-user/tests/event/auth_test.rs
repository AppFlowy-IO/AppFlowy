use crate::helper::*;
use flowy_test::{event_builder::UserModuleEventBuilder, FlowySDKTest};
use flowy_user::{errors::ErrorCode, event_map::UserEvent::*};
use flowy_user_data_model::entities::{SignInPayload, SignUpPayload, UserProfile};

#[tokio::test]
async fn sign_up_with_invalid_email() {
    for email in invalid_email_test_case() {
        let sdk = FlowySDKTest::default();
        let request = SignUpPayload {
            email: email.to_string(),
            name: valid_name(),
            password: login_password(),
        };

        assert_eq!(
            UserModuleEventBuilder::new(sdk)
                .event(SignUp)
                .payload(request)
                .async_send()
                .await
                .error()
                .code,
            ErrorCode::EmailFormatInvalid.value()
        );
    }
}
#[tokio::test]
async fn sign_up_with_invalid_password() {
    for password in invalid_password_test_case() {
        let sdk = FlowySDKTest::default();
        let request = SignUpPayload {
            email: random_email(),
            name: valid_name(),
            password,
        };

        UserModuleEventBuilder::new(sdk)
            .event(SignUp)
            .payload(request)
            .async_send()
            .await
            .assert_error();
    }
}

#[tokio::test]
async fn sign_in_success() {
    let test = FlowySDKTest::default();
    let _ = UserModuleEventBuilder::new(test.clone()).event(SignOut).sync_send();
    let sign_up_context = test.sign_up().await;

    let request = SignInPayload {
        email: sign_up_context.user_profile.email.clone(),
        password: sign_up_context.password.clone(),
        name: "".to_string(),
    };

    let response = UserModuleEventBuilder::new(test.clone())
        .event(SignIn)
        .payload(request)
        .async_send()
        .await
        .parse::<UserProfile>();
    dbg!(&response);
}

#[tokio::test]
async fn sign_in_with_invalid_email() {
    for email in invalid_email_test_case() {
        let sdk = FlowySDKTest::default();
        let request = SignInPayload {
            email: email.to_string(),
            password: login_password(),
            name: "".to_string(),
        };

        assert_eq!(
            UserModuleEventBuilder::new(sdk)
                .event(SignIn)
                .payload(request)
                .async_send()
                .await
                .error()
                .code,
            ErrorCode::EmailFormatInvalid.value()
        );
    }
}

#[tokio::test]
async fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let sdk = FlowySDKTest::default();

        let request = SignInPayload {
            email: random_email(),
            password,
            name: "".to_string(),
        };

        UserModuleEventBuilder::new(sdk)
            .event(SignIn)
            .payload(request)
            .async_send()
            .await
            .assert_error();
    }
}
