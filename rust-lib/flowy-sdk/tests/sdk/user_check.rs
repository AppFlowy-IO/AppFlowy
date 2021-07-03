use super::helper::*;
use flowy_sys::prelude::*;
use flowy_user::prelude::*;
use tokio::time::{sleep, Duration};

#[test]
#[should_panic]
fn auth_check_no_payload() {
    let resp = EventTester::new(AuthCheck, Payload::None).sync_send();
    assert_eq!(resp.status_code, StatusCode::Ok);
}

#[tokio::test]
async fn auth_check_with_user_name_email_payload() {
    // let user_data = UserData::new("jack".to_owned(),
    // "helloworld@gmail.com".to_owned());
    //
    //
    // EventTester::new(AuthCheck)
    //     .bytes_payload(user_data)
    //     .sync_send();
}
