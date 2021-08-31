use crate::helper::*;
use flowy_user::{errors::ErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn user_update_with_name() {
    let user_detail = TestBuilder::new().login().user_detail.unwrap();
    let new_name = "hello_world".to_owned();
    let request = UpdateUserRequest::new(&user_detail.id).name(&new_name);
    let _ = TestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send();

    let user_detail = TestBuilder::new()
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.name, new_name,);
}

#[test]
#[serial]
fn user_update_with_email() {
    let user_detail = TestBuilder::new().login().user_detail.unwrap();
    let new_email = "123@gmai.com".to_owned();
    let request = UpdateUserRequest::new(&user_detail.id).email(&new_email);

    let _ = TestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send();

    let user_detail = TestBuilder::new()
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.email, new_email,);
}

#[test]
#[serial]
fn user_update_with_password() {
    let user_detail = TestBuilder::new().login().user_detail.unwrap();
    let new_password = "H123world!".to_owned();
    let request = UpdateUserRequest::new(&user_detail.id).password(&new_password);

    let _ = TestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_success();
}

#[test]
#[serial]
fn user_update_with_invalid_email() {
    let user_detail = TestBuilder::new().login().user_detail.unwrap();
    for email in invalid_email_test_case() {
        let request = UpdateUserRequest::new(&user_detail.id).email(&email);
        assert_eq!(
            TestBuilder::new()
                .event(UpdateUser)
                .request(request)
                .sync_send()
                .error()
                .code,
            ErrorCode::EmailFormatInvalid
        );
    }
}

#[test]
#[serial]
fn user_update_with_invalid_password() {
    let user_detail = TestBuilder::new().login().user_detail.unwrap();
    for password in invalid_password_test_case() {
        let request = UpdateUserRequest::new(&user_detail.id).password(&password);

        TestBuilder::new()
            .event(UpdateUser)
            .request(request)
            .sync_send()
            .assert_error();
    }
}

#[test]
#[serial]
fn user_update_with_invalid_name() {
    let user_detail = TestBuilder::new().login().user_detail.unwrap();
    let request = UpdateUserRequest::new(&user_detail.id).name("");

    TestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_error();
}
