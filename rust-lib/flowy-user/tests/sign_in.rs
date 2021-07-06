use flowy_test::prelude::*;
use flowy_user::prelude::*;

#[test]
#[should_panic]
fn sign_in_without_password() {
    let params = UserSignInParams {
        email: "annie@appflowy.io".to_string(),
        password: "".to_string(),
    };

    let result = EventTester::new(SignIn)
        .payload(params)
        .assert_status_code(StatusCode::Err)
        .sync_send::<UserSignInResult>();
    dbg!(&result);
}

#[test]
#[should_panic]
fn sign_in_without_email() {
    let params = UserSignInParams {
        email: "".to_string(),
        password: "HelloWorld!123".to_string(),
    };

    let result = EventTester::new(SignIn)
        .payload(params)
        .assert_status_code(StatusCode::Err)
        .sync_send::<UserSignInResult>();
    dbg!(&result);
}
