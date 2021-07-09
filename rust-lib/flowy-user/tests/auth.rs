use flowy_test::prelude::*;
use flowy_user::{event::UserEvent::*, prelude::*};

#[test]
fn sign_up_success() {
    let request = SignUpRequest {
        email: valid_email(),
        name: valid_name(),
        password: valid_password(),
    };

    let response = EventTester::new(SignUp)
        .request(request)
        .sync_send()
        .parse::<SignUpResponse>();
    dbg!(&response);
}

#[test]
fn sign_in_success() {
    let request = SignInRequest {
        email: valid_email(),
        password: valid_password(),
    };

    let response = EventTester::new(SignIn)
        .request(request)
        .sync_send()
        .parse::<SignInResponse>();
    dbg!(&response);
}

#[test]
fn sign_up_with_invalid_email() {
    for email in invalid_email_test_case() {
        let request = SignUpRequest {
            email: email.to_string(),
            name: valid_name(),
            password: valid_password(),
        };

        let _ = EventTester::new(SignUp)
            .request(request)
            .assert_error()
            .sync_send();
    }
}
#[test]
fn sign_up_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignUpRequest {
            email: valid_email(),
            name: valid_name(),
            password,
        };

        let _ = EventTester::new(SignUp)
            .request(request)
            .assert_error()
            .sync_send();
    }
}
#[test]
fn sign_in_with_invalid_email() {
    for email in invalid_email_test_case() {
        let request = SignInRequest {
            email: email.to_string(),
            password: valid_password(),
        };

        let _ = EventTester::new(SignIn)
            .request(request)
            .assert_error()
            .sync_send();
    }
}

#[test]
fn sign_in_with_invalid_password() {
    for password in invalid_password_test_case() {
        let request = SignInRequest {
            email: valid_email(),
            password,
        };

        let _ = EventTester::new(SignIn)
            .request(request)
            .assert_error()
            .sync_send();
    }
}

fn invalid_email_test_case() -> Vec<String> {
    // https://gist.github.com/cjaoude/fd9910626629b53c4d25
    vec![
        "",
        "annie@",
        "annie@gmail@",
        "#@%^%#$@#$@#.com",
        "@example.com",
        "Joe Smith <email@example.com>",
        "email.example.com",
        "email@example@example.com",
        "email@-example.com",
        "email@example..com",
        "あいうえお@example.com",
        /* The following email is valid according to the validate_email function return
         * ".email@example.com",
         * "email.@example.com",
         * "email..email@example.com",
         * "email@example",
         * "email@example.web",
         * "email@111.222.333.44444",
         * "Abc..123@example.com", */
    ]
    .iter()
    .map(|s| s.to_string())
    .collect::<Vec<_>>()
}

fn invalid_password_test_case() -> Vec<String> {
    vec!["", "123456", "1234".repeat(100).as_str()]
        .iter()
        .map(|s| s.to_string())
        .collect::<Vec<_>>()
}

fn valid_email() -> String { "annie@appflowy.io".to_string() }

fn valid_password() -> String { "HelloWorld!123".to_string() }

fn valid_name() -> String { "AppFlowy".to_string() }
