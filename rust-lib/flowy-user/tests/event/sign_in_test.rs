use crate::helper::*;
use flowy_test::prelude::*;
use flowy_user::{
    errors::{UserError, UserErrorCode},
    event::UserEvent::*,
    prelude::*,
};
use serial_test::*;

#[test]
#[serial]
fn sign_in_success() {
    let _ = EventTester::new(SignOut).sync_send();
    let request = SignInRequest {
        email: valid_email(),
        password: valid_password(),
    };

    let response = EventTester::new(SignIn)
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
            EventTester::new(SignIn)
                .request(request)
                .sync_send()
                .parse::<UserError>()
                .code,
            UserErrorCode::EmailInvalid
        );
    }
}

#[test]
fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignInRequest {
            email: valid_email(),
            password,
        };

        assert_eq!(
            EventTester::new(SignIn)
                .request(request)
                .sync_send()
                .parse::<UserError>()
                .code,
            UserErrorCode::PasswordInvalid
        );
    }
}
