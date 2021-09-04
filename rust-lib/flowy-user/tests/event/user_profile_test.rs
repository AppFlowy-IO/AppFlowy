use crate::helper::*;
use flowy_infra::uuid;
use flowy_test::{builder::UserTestBuilder, init_test_sdk};
use flowy_user::{errors::ErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn user_profile_get_failed() {
    let sdk = init_test_sdk();
    let result = UserTestBuilder::new(sdk).event(GetUserProfile).assert_error().sync_send();
    assert!(result.user_detail().is_none())
}

#[test]
#[serial]
fn user_profile_get() {
    let sdk = init_test_sdk();
    let user_detail = UserTestBuilder::new(sdk.clone()).sign_up().user_detail;

    let user_detail2 = UserTestBuilder::new(sdk).event(GetUserProfile).sync_send().parse::<UserDetail>();

    assert_eq!(user_detail, user_detail2);
}

#[test]
#[serial]
fn user_update_with_name() {
    let sdk = init_test_sdk();
    let user_detail = UserTestBuilder::new(sdk.clone()).sign_up().user_detail;
    let new_name = "hello_world".to_owned();
    let request = UpdateUserRequest::new(&user_detail.id).name(&new_name);
    let _ = UserTestBuilder::new(sdk.clone()).event(UpdateUser).request(request).sync_send();

    let user_detail = UserTestBuilder::new(sdk)
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.name, new_name,);
}

#[test]
#[serial]
fn user_update_with_email() {
    let sdk = init_test_sdk();
    let user_detail = UserTestBuilder::new(sdk.clone()).sign_up().user_detail;
    let new_email = format!("{}@gmai.com", uuid());
    let request = UpdateUserRequest::new(&user_detail.id).email(&new_email);

    let _ = UserTestBuilder::new(sdk.clone()).event(UpdateUser).request(request).sync_send();

    let user_detail = UserTestBuilder::new(sdk)
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.email, new_email,);
}

#[test]
#[serial]
fn user_update_with_password() {
    let sdk = init_test_sdk();
    let user_detail = UserTestBuilder::new(sdk.clone()).sign_up().user_detail;
    let new_password = "H123world!".to_owned();
    let request = UpdateUserRequest::new(&user_detail.id).password(&new_password);

    let _ = UserTestBuilder::new(sdk)
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_success();
}

#[test]
#[serial]
fn user_update_with_invalid_email() {
    let sdk = init_test_sdk();
    let user_detail = UserTestBuilder::new(sdk.clone()).sign_up().user_detail;
    for email in invalid_email_test_case() {
        let request = UpdateUserRequest::new(&user_detail.id).email(&email);
        assert_eq!(
            UserTestBuilder::new(sdk.clone())
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
    let sdk = init_test_sdk();
    let user_detail = UserTestBuilder::new(sdk.clone()).sign_up().user_detail;
    for password in invalid_password_test_case() {
        let request = UpdateUserRequest::new(&user_detail.id).password(&password);

        UserTestBuilder::new(sdk.clone())
            .event(UpdateUser)
            .request(request)
            .sync_send()
            .assert_error();
    }
}

#[test]
#[serial]
fn user_update_with_invalid_name() {
    let sdk = init_test_sdk();
    let user_detail = UserTestBuilder::new(sdk.clone()).sign_up().user_detail;
    let request = UpdateUserRequest::new(&user_detail.id).name("");

    UserTestBuilder::new(sdk)
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_error();
}
