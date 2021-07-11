use crate::helper::*;
use flowy_test::prelude::*;
use flowy_user::{event::UserEvent::*, prelude::*};
#[test]
#[should_panic]
fn user_status_not_found_before_login() {
    let _ = EventTester::new(SignOut).sync_send();
    let _ = EventTester::new(GetStatus)
        .sync_send()
        .parse::<UserDetail>();
}

#[test]
fn user_status_did_found_after_login() {
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

    let _ = EventTester::new(GetStatus)
        .sync_send()
        .parse::<UserDetail>();
}
