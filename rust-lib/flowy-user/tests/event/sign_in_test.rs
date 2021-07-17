use crate::helper::*;
use flowy_user::{errors::UserErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn sign_in_success() {
    let request = SignInRequest {
        email: random_valid_email(),
        password: valid_password(),
    };

    let response = UserTestBuilder::new()
        .logout()
        .event(SignIn)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();
    dbg!(&response);
}

#[test]
fn sign_in_with_invalid_email() {
    for email in invalid_email_test_case() {
        let request = SignInRequest {
            email: email.to_string(),
            password: valid_password(),
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(SignIn)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::EmailInvalid
        );
    }
}

#[test]
fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignInRequest {
            email: random_valid_email(),
            password,
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(SignIn)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::PasswordInvalid
        );
    }
}
