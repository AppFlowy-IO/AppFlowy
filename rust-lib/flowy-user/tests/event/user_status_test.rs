use crate::helper::*;
use flowy_user::{event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn user_status_get_failed_before_login() {
    let a = UserTestBuilder::new()
        .logout()
        .event(GetStatus)
        .assert_error()
        .sync_send();
}

#[test]
#[serial]
fn user_status_get_success_after_login() {
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

    let _ = UserTestBuilder::new()
        .event(GetStatus)
        .sync_send()
        .parse::<UserDetail>();
}
