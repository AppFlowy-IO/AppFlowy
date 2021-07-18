use crate::helper::*;
use flowy_user::{errors::UserErrorCode, event::UserEvent::*, prelude::*};
use serial_test::*;

#[test]
#[serial]
fn sign_in_success() {
    let request = SignInRequest {
        email: random_valid_email(),
        password: valid_password(),
    };

    let response = UserTestBuilder::new()
        .logout()
        .event(SignIn)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();
    dbg!(&response);
}

#[test]
#[serial]
fn sign_in_with_invalid_email() {
    for email in invalid_email_test_case() {
        let request = SignInRequest {
            email: email.to_string(),
            password: valid_password(),
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(SignIn)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::EmailInvalid
        );
    }
}

#[test]
#[serial]
fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignInRequest {
            email: random_valid_email(),
            password,
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(SignIn)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::PasswordInvalid
        );
    }
}

#[test]
#[serial]
fn sign_up_success() {
    let _ = UserTestBuilder::new().event(SignOut).sync_send();
    let request = SignUpRequest {
        email: random_valid_email(),
        name: valid_name(),
        password: valid_password(),
    };

    let _response = UserTestBuilder::new()
        .logout()
        .event(SignUp)
        .request(request)
        .sync_send();
}

#[test]
#[serial]
fn sign_up_with_invalid_email() {
    for email in invalid_email_test_case() {
        let request = SignUpRequest {
            email: email.to_string(),
            name: valid_name(),
            password: valid_password(),
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(SignUp)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::EmailInvalid
        );
    }
}
#[test]
#[serial]
fn sign_up_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignUpRequest {
            email: random_valid_email(),
            name: valid_name(),
            password,
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(SignUp)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::PasswordInvalid
        );
    }
}

#[test]
#[should_panic]
#[serial]
fn user_status_get_failed_before_login() {
    let _ = UserTestBuilder::new()
        .logout()
        .event(GetStatus)
        .sync_send()
        .parse::<UserDetail>();
}

#[test]
#[serial]
fn user_status_get_success_after_login() {
    let request = SignInRequest {
        email: random_valid_email(),
        password: valid_password(),
    };

    let response = UserTestBuilder::new()
        .logout()
        .event(SignIn)
        .request(request)
        .sync_send()
        .parse::<UserDetail>();
    dbg!(&response);

    let _ = UserTestBuilder::new()
        .event(GetStatus)
        .sync_send()
        .parse::<UserDetail>();
}

#[test]
#[serial]
fn user_update_with_name() {
    let user_detail = UserTestBuilder::new().login().user_detail.unwrap();
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
    let user_detail = UserTestBuilder::new().login().user_detail.unwrap();
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
    let user_detail = UserTestBuilder::new().login().user_detail.unwrap();
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
    let user_detail = UserTestBuilder::new().login().user_detail.unwrap();
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
            UserErrorCode::EmailInvalid
        );
    }
}

#[test]
#[serial]
fn user_update_with_invalid_password() {
    let user_detail = UserTestBuilder::new().login().user_detail.unwrap();
    for password in invalid_password_test_case() {
        let request = UpdateUserRequest {
            id: user_detail.id.clone(),
            name: None,
            email: None,
            workspace: None,
            password: Some(password),
        };

        assert_eq!(
            UserTestBuilder::new()
                .event(UpdateUser)
                .request(request)
                .sync_send()
                .error()
                .code,
            UserErrorCode::PasswordInvalid
        );
    }
}

#[test]
#[serial]
fn user_update_with_invalid_name() {
    let user_detail = UserTestBuilder::new().login().user_detail.unwrap();
    let request = UpdateUserRequest {
        id: user_detail.id.clone(),
        name: Some("".to_string()),
        email: None,
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
        UserErrorCode::UserNameInvalid
    );
}
