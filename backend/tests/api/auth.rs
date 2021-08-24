use crate::helper::{spawn_app, TestApp};
use flowy_user::entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse};

#[actix_rt::test]
async fn user_register() {
    let app = spawn_app().await;
    let response = register_user(&app, "annie@appflowy.io", "HelloWork123!").await;
    log::info!("{:?}", response);
}

#[actix_rt::test]
#[should_panic]
async fn user_sign_in_with_invalid_password() {
    let app = spawn_app().await;
    let email = "annie@appflowy.io";
    let password = "123";
    let _ = register_user(&app, email, password).await;
}

#[actix_rt::test]
#[should_panic]
async fn user_sign_in_with_invalid_email() {
    let app = spawn_app().await;
    let email = "annie@gmail@";
    let password = "HelloWork123!";
    let _ = register_user(&app, email, password).await;
}

#[actix_rt::test]
async fn user_sign_in() {
    let app = spawn_app().await;
    let email = "annie@appflowy.io";
    let password = "HelloWork123!";
    let _ = register_user(&app, email, password).await;
    let response = app
        .sign_in(SignInParams {
            email: email.to_string(),
            password: password.to_string(),
        })
        .await;

    log::info!("{:?}", response);
}

async fn register_user(app: &TestApp, email: &str, password: &str) -> SignUpResponse {
    let params = SignUpParams {
        email: email.to_string(),
        name: "annie".to_string(),
        password: password.to_string(),
    };

    let response = app.register_user(params).await;
    response
}
