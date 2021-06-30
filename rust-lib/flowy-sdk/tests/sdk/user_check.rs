use super::helper::*;
use flowy_sys::prelude::*;
use flowy_user::prelude::*;

#[test]
fn auth_check_no_payload() {
    let callback = |_, resp: EventResponse| {
        assert_eq!(resp.status, StatusCode::Err);
    };

    FlowySDKTester::new(AuthCheck).callback(callback).run();
}

#[test]
fn auth_check_with_user_name_email_payload() {
    let callback = |_, resp: EventResponse| {
        assert_eq!(resp.status, StatusCode::Ok);
    };

    let user_data = UserData::new("jack".to_owned(), "helloworld@gmail.com".to_owned());

    FlowySDKTester::new(AuthCheck)
        .bytes_payload(user_data)
        .callback(callback)
        .run();
}
