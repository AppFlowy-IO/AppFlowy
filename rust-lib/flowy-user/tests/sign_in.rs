use flowy_test::prelude::*;
use flowy_user::prelude::*;

#[test]
fn sign_in_with_invalid_email() {
    let test_cases = vec!["", "annie@", "annie@gmail@"];
    let password = "Appflowy!123".to_string();

    for email in test_cases {
        let params = UserSignInParams {
            email: email.to_string(),
            password: password.clone(),
        };

        let _ = EventTester::new(SignIn)
            .payload(params)
            .assert_status_code(StatusCode::Err)
            .sync_send();
    }
}

#[test]
fn sign_in_with_invalid_password() {
    let test_cases = vec!["".to_string(), "123456".to_owned(), "1234".repeat(100)];
    let email = "annie@appflowy.io".to_string();

    for password in test_cases {
        let params = UserSignInParams {
            email: email.clone(),
            password,
        };

        let _ = EventTester::new(SignIn)
            .payload(params)
            .assert_status_code(StatusCode::Err)
            .sync_send();
    }
}

#[test]
fn sign_in_success() {
    let params = UserSignInParams {
        email: "annie@appflowy.io".to_string(),
        password: "HelloWorld!123".to_string(),
    };

    let result = EventTester::new(SignIn)
        .payload(params)
        .assert_status_code(StatusCode::Ok)
        .sync_send()
        .parse::<UserSignInResult>();
    dbg!(&result);
}
