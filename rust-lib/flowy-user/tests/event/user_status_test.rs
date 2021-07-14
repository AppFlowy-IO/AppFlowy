use crate::helper::*;

use flowy_user::{errors::UserErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[should_panic]
#[serial]
fn user_status_not_found_before_login() {
    let _ = UserEventTester::new(SignOut).sync_send();
    let _ = UserEventTester::new(GetStatus)
        .sync_send()
        .parse::<UserDetail>();
}

#[test]
#[serial]
fn user_status_did_found_after_login() {
    let _ = UserEventTester::new(SignOut).sync_send();
    let request = SignInRequest {
        email: valid_email(),
        password: valid_password(),
    };

    let response = UserEventTester::new(SignIn)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();
    dbg!(&response);

    let _ = UserEventTester::new(GetStatus)
        .sync_send()
        .parse::<UserDetail>();
}

#[test]
#[serial]
fn user_update_with_invalid_email() {
    let _ = UserEventTester::new(SignOut).sync_send();
    let request = SignInRequest {
        email: valid_email(),
        password: valid_password(),
    };

    let _ = UserEventTester::new(SignIn)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();

    let user_detail = UserEventTester::new(GetStatus)
        .sync_send()
        .parse::<UserDetail>();

    for email in invalid_email_test_case() {
        let request = UpdateUserRequest {
            id: user_detail.id.clone(),
            name: None,
            email: Some(email),
            workspace: None,
            password: None,
        };

        assert_eq!(
            UserEventTester::new(UpdateUser)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::EmailInvalid
        );
    }
}
