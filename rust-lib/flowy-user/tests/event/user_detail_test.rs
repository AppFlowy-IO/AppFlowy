use crate::helper::*;
use flowy_user::{event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn user_status_get_failed() {
    let _ = TestBuilder::new()
        .logout()
        .event(GetUserProfile)
        .assert_error()
        .sync_send();
}

#[test]
#[serial]
fn user_detail_get() {
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

    let _ = TestBuilder::new()
        .event(GetUserProfile)
        .sync_send()
        .parse::<UserDetail>();
}
