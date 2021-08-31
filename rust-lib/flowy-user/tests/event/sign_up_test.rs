use crate::helper::*;
use flowy_user::{errors::*, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn sign_up_success() {
    let request = SignUpRequest {
        email: random_email(),
        name: valid_name(),
        password: valid_password(),
    };

    let _response = TestBuilder::new()
        .logout()
        .event(SignUp)
        .request(request)
        .sync_send();
}

#[test]
#[serial]
fn sign_up_with_invalid_email() {
    for email in invalid_email_test_case() {
        let request = SignUpRequest {
            email: email.to_string(),
            name: valid_name(),
            password: valid_password(),
        };

        assert_eq!(
            TestBuilder::new()
                .event(SignUp)
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
fn sign_up_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignUpRequest {
            email: random_email(),
            name: valid_name(),
            password,
        };

        TestBuilder::new()
            .event(SignUp)
            .request(request)
            .sync_send()
            .assert_error();
    }
}
