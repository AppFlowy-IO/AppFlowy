use crate::helper::*;
use flowy_test::{builder::UserTest, init_test_sdk, FlowyEnv};
use flowy_user::{errors::ErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn sign_up_with_invalid_email() {
    for email in invalid_email_test_case() {
        let sdk = init_test_sdk();
        let request = SignUpRequest {
            email: email.to_string(),
            name: valid_name(),
            password: login_password(),
        };

        assert_eq!(
            UserTest::new(sdk).event(SignUp).request(request).sync_send().error().code,
            ErrorCode::EmailFormatInvalid
        );
    }
}
#[test]
#[serial]
fn sign_up_with_invalid_password() {
    for password in invalid_password_test_case() {
        let sdk = init_test_sdk();
        let request = SignUpRequest {
            email: random_email(),
            name: valid_name(),
            password,
        };

        UserTest::new(sdk).event(SignUp).request(request).sync_send().assert_error();
    }
}

#[test]
#[serial]
fn sign_in_success() {
    let env = FlowyEnv::setup();
    let _ = UserTest::new(env.sdk()).event(SignOut).sync_send();

    let request = SignInRequest {
        email: env.user.email.clone(),
        password: env.password.clone(),
    };

    let response = UserTest::new(env.sdk())
        .event(SignIn)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();
    dbg!(&response);
}

#[test]
#[serial]
fn sign_in_with_invalid_email() {
    for email in invalid_email_test_case() {
        let sdk = init_test_sdk();
        let request = SignInRequest {
            email: email.to_string(),
            password: login_password(),
        };

        assert_eq!(
            UserTest::new(sdk).event(SignIn).request(request).sync_send().error().code,
            ErrorCode::EmailFormatInvalid
        );
    }
}

#[test]
#[serial]
fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let sdk = init_test_sdk();
        let request = SignInRequest {
            email: random_email(),
            password,
        };

        UserTest::new(sdk).event(SignIn).request(request).sync_send().assert_error();
    }
}
