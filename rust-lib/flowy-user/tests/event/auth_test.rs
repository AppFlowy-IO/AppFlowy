use crate::helper::*;
use flowy_test::builder::UserTestBuilder;
use flowy_user::{errors::ErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn sign_up_success() {
    let user_detail = UserTestBuilder::new().sign_up().user_detail;
    log::info!("{:?}", user_detail);
}

#[test]
#[serial]
fn sign_up_with_invalid_email() {
    for email in invalid_email_test_case() {
        let request = SignUpRequest {
            email: email.to_string(),
            name: valid_name(),
            password: login_password(),
        };

        assert_eq!(
            UserTestBuilder::new().event(SignUp).request(request).sync_send().error().code,
            ErrorCode::EmailFormatInvalid
        );
    }
}
#[test]
#[serial]
fn sign_up_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignUpRequest {
            email: random_email(),
            name: valid_name(),
            password,
        };

        UserTestBuilder::new().event(SignUp).request(request).sync_send().assert_error();
    }
}

#[test]
#[serial]
fn sign_in_success() {
    let context = UserTestBuilder::new().sign_up();

    let _ = UserTestBuilder::new().event(SignOut).sync_send();

    let request = SignInRequest {
        email: context.user_detail.email,
        password: context.password,
    };

    let response = UserTestBuilder::new()
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
        let request = SignInRequest {
            email: email.to_string(),
            password: login_password(),
        };

        assert_eq!(
            UserTestBuilder::new().event(SignIn).request(request).sync_send().error().code,
            ErrorCode::EmailFormatInvalid
        );
    }
}

#[test]
#[serial]
fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignInRequest {
            email: random_email(),
            password,
        };

        UserTestBuilder::new().event(SignIn).request(request).sync_send().assert_error();
    }
}
