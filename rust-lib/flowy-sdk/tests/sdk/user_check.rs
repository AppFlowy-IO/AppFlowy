use super::helper::*;
use flowy_sys::prelude::*;
use flowy_user::prelude::*;
use tokio::time::{sleep, Duration};

#[test]
fn auth_check_no_payload() {
    let callback = |_, resp: EventResponse| {
        assert_eq!(resp.status, StatusCode::Err);
    };

    let resp = FlowySDKTester::new(AuthCheck).sync_send();
}

#[tokio::test]
async fn auth_check_with_user_name_email_payload() {
    let user_data = UserData::new("jack".to_owned(), "helloworld@gmail.com".to_owned());

    FlowySDKTester::new(AuthCheck)
        .bytes_payload(user_data)
        .sync_send();
}
