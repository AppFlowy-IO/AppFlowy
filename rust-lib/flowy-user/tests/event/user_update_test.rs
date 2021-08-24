use crate::helper::*;
use flowy_user::{errors::UserErrCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn user_update_with_name() {
    let user_detail = UserTestBuilder::new().reset().user_detail.unwrap();
    let new_name = "hello_world".to_owned();
    let request = UpdateUserRequest {
        id: user_detail.id.clone(),
        name: Some(new_name.clone()),
        email: None,
        workspace: None,
        password: None,
    };

    let user_detail = UserTestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.name, new_name,);
}

#[test]
#[serial]
fn user_update_with_email() {
    let user_detail = UserTestBuilder::new().reset().user_detail.unwrap();
    let new_email = "123@gmai.com".to_owned();
    let request = UpdateUserRequest {
        id: user_detail.id.clone(),
        name: None,
        email: Some(new_email.clone()),
        workspace: None,
        password: None,
    };

    let user_detail = UserTestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();

    assert_eq!(user_detail.email, new_email,);
}

#[test]
#[serial]
fn user_update_with_password() {
    let user_detail = UserTestBuilder::new().reset().user_detail.unwrap();
    let new_password = "H123world!".to_owned();
    let request = UpdateUserRequest {
        id: user_detail.id.clone(),
        name: None,
        email: None,
        workspace: None,
        password: Some(new_password.clone()),
    };

    let _ = UserTestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_success();
}

#[test]
#[serial]
fn user_update_with_invalid_email() {
    let user_detail = UserTestBuilder::new().reset().user_detail.unwrap();
    for email in invalid_email_test_case() {
        let request = UpdateUserRequest {
            id: user_detail.id.clone(),
            name: None,
            email: Some(email),
            workspace: None,
            password: None,
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(UpdateUser)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrCode::EmailFormatInvalid
        );
    }
}

#[test]
#[serial]
fn user_update_with_invalid_password() {
    let user_detail = UserTestBuilder::new().reset().user_detail.unwrap();
    for password in invalid_password_test_case() {
        let request = UpdateUserRequest {
            id: user_detail.id.clone(),
            name: None,
            email: None,
            workspace: None,
            password: Some(password),
        };

        UserTestBuilder::new()
            .event(UpdateUser)
            .request(request)
            .sync_send()
            .assert_error();
    }
}

#[test]
#[serial]
fn user_update_with_invalid_name() {
    let user_detail = UserTestBuilder::new().reset().user_detail.unwrap();
    let request = UpdateUserRequest {
        id: user_detail.id.clone(),
        name: Some("".to_string()),
        email: None,
        workspace: None,
        password: None,
    };

    UserTestBuilder::new()
        .event(UpdateUser)
        .request(request)
        .sync_send()
        .assert_error();
}
