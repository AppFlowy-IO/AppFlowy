use crate::helper::spawn_app;
use flowy_user::entities::{SignInParams, SignInResponse, SignUpParams};

#[actix_rt::test]
async fn user_register() {
    let app = spawn_app().await;
    let params = SignUpParams {
        email: "annie@appflowy.io".to_string(),
        name: "annie".to_string(),
        password: "123".to_string(),
    };

    let response = app.register_user(params).await;
    log::info!("{:?}", response);
}

#[actix_rt::test]
async fn user_sign_in() {
    let app = spawn_app().await;
    let email = "annie@appflowy.io";
    let password = "123";

    let _ = app
        .register_user(SignUpParams {
            email: email.to_string(),
            name: "annie".to_string(),
            password: password.to_string(),
        })
        .await;

    let response = app
        .sign_in(SignInParams {
            email: email.to_string(),
            password: password.to_string(),
        })
        .await;

    log::info!("{:?}", response);
}
