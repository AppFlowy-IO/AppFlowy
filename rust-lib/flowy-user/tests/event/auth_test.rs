use crate::helper::*;
use flowy_test::{builder::UserTestBuilder, init_test_sdk};
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
            UserTestBuilder::new(sdk).event(SignUp).request(request).sync_send().error().code,
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

        UserTestBuilder::new(sdk).event(SignUp).request(request).sync_send().assert_error();
    }
}

#[test]
#[serial]
fn sign_in_success() {
    let sdk = init_test_sdk();
    let context = UserTestBuilder::new(sdk.clone()).sign_up();
    let _ = UserTestBuilder::new(sdk.clone()).event(SignOut).sync_send();

    let request = SignInRequest {
        email: context.user_detail.email,
        password: context.password,
    };

    let response = UserTestBuilder::new(sdk)
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
            UserTestBuilder::new(sdk).event(SignIn).request(request).sync_send().error().code,
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

        UserTestBuilder::new(sdk).event(SignIn).request(request).sync_send().assert_error();
    }
}
