use crate::helper::*;
use flowy_user::{errors::ErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn sign_in_success() {
    let request = SignInRequest {
        email: random_email(),
        password: valid_password(),
    };

    let response = TestBuilder::new()
        .logout()
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
            password: valid_password(),
        };

        assert_eq!(
            TestBuilder::new()
                .event(SignIn)
                .request(request)
                .sync_send()
                .error()
                .code,
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

        TestBuilder::new()
            .event(SignIn)
            .request(request)
            .sync_send()
            .assert_error();
    }
}
