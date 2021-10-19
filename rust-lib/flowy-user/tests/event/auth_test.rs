use crate::helper::*;
use flowy_test::{builder::UserTest, FlowyTest};
use flowy_user::{errors::ErrorCode, event::UserEvent::*, prelude::*};

#[tokio::test]
async fn sign_up_with_invalid_email() {
    for email in invalid_email_test_case() {
        let test = FlowyTest::setup();
        let request = SignUpRequest {
            email: email.to_string(),
            name: valid_name(),
            password: login_password(),
        };

        assert_eq!(
            UserTest::new(test.sdk)
                .event(SignUp)
                .request(request)
                .async_send()
                .await
                .error()
                .code,
            ErrorCode::EmailFormatInvalid
        );
    }
}
#[tokio::test]
async fn sign_up_with_invalid_password() {
    for password in invalid_password_test_case() {
        let test = FlowyTest::setup();
        let request = SignUpRequest {
            email: random_email(),
            name: valid_name(),
            password,
        };

        UserTest::new(test.sdk)
            .event(SignUp)
            .request(request)
            .async_send()
            .await
            .assert_error();
    }
}

#[tokio::test]
async fn sign_in_success() {
    let test = FlowyTest::setup();
    let _ = UserTest::new(test.sdk()).event(SignOut).sync_send();
    let sign_up_context = test.sign_up().await;

    let request = SignInRequest {
        email: sign_up_context.user_profile.email.clone(),
        password: sign_up_context.password.clone(),
    };

    let response = UserTest::new(test.sdk())
        .event(SignIn)
        .request(request)
        .async_send()
        .await
        .parse::<UserProfile>();
    dbg!(&response);
}

#[tokio::test]
async fn sign_in_with_invalid_email() {
    for email in invalid_email_test_case() {
        let test = FlowyTest::setup();
        let request = SignInRequest {
            email: email.to_string(),
            password: login_password(),
        };

        assert_eq!(
            UserTest::new(test.sdk)
                .event(SignIn)
                .request(request)
                .async_send()
                .await
                .error()
                .code,
            ErrorCode::EmailFormatInvalid
        );
    }
}

#[tokio::test]
async fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let test = FlowyTest::setup();

        let request = SignInRequest {
            email: random_email(),
            password,
        };

        UserTest::new(test.sdk)
            .event(SignIn)
            .request(request)
            .async_send()
            .await
            .assert_error();
    }
}
