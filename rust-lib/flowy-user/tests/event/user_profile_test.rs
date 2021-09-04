use crate::helper::*;
use flowy_infra::uuid;
use flowy_test::{builder::UserTest, init_test_sdk, FlowyEnv};
use flowy_user::{errors::ErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn user_profile_get_failed() {
    let sdk = init_test_sdk();
    let result = UserTest::new(sdk).event(GetUserProfile).assert_error().sync_send();
    assert!(result.user_detail().is_none())
}

#[test]
#[serial]
fn user_profile_get() {
    let env = FlowyEnv::setup();
    let user = UserTest::new(env.sdk.clone())
        .event(GetUserProfile)
        .sync_send()
        .parse::<UserDetail>();
    assert_eq!(env.user, user);
}

#[test]
#[serial]
fn user_update_with_name() {
    let env = FlowyEnv::setup();
    let new_name = "hello_world".to_owned();
    let request = UpdateUserRequest::new(&env.user.id).name(&new_name);
    let _ = UserTest::new(env.sdk()).event(UpdateUser).request(request).sync_send();

    let user_detail = UserTest::new(env.sdk())
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.name, new_name,);
}

#[test]
#[serial]
fn user_update_with_email() {
    let env = FlowyEnv::setup();
    let new_email = format!("{}@gmai.com", uuid());
    let request = UpdateUserRequest::new(&env.user.id).email(&new_email);
    let _ = UserTest::new(env.sdk()).event(UpdateUser).request(request).sync_send();
    let user_detail = UserTest::new(env.sdk())
        .event(GetUserProfile)
        .assert_error()
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.email, new_email,);
}

#[test]
#[serial]
fn user_update_with_password() {
    let env = FlowyEnv::setup();
    let new_password = "H123world!".to_owned();
    let request = UpdateUserRequest::new(&env.user.id).password(&new_password);

    let _ = UserTest::new(env.sdk())
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_success();
}

#[test]
#[serial]
fn user_update_with_invalid_email() {
    let env = FlowyEnv::setup();
    for email in invalid_email_test_case() {
        let request = UpdateUserRequest::new(&env.user.id).email(&email);
        assert_eq!(
            UserTest::new(env.sdk()).event(UpdateUser).request(request).sync_send().error().code,
            ErrorCode::EmailFormatInvalid
        );
    }
}

#[test]
#[serial]
fn user_update_with_invalid_password() {
    let env = FlowyEnv::setup();
    for password in invalid_password_test_case() {
        let request = UpdateUserRequest::new(&env.user.id).password(&password);

        UserTest::new(env.sdk())
            .event(UpdateUser)
            .request(request)
            .sync_send()
            .assert_error();
    }
}

#[test]
#[serial]
fn user_update_with_invalid_name() {
    let env = FlowyEnv::setup();
    let request = UpdateUserRequest::new(&env.user.id).name("");
    UserTest::new(env.sdk())
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_error();
}
