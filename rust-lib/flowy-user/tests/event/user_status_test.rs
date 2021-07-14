use crate::helper::*;
use flowy_test::prelude::*;
use flowy_user::{event::UserEvent::*, prelude::*};
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
