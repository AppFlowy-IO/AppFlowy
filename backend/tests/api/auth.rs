use crate::helper::{spawn_app, TestApp};
use flowy_user::{
    entities::{
        SignInParams,
        SignInResponse,
        SignUpParams,
        SignUpResponse,
        UpdateUserParams,
        UserToken,
    },
    errors::UserError,
};

#[actix_rt::test]
async fn user_register() {
    let app = spawn_app().await;
    let response = register_user(&app, "annie@appflowy.io", "HelloWorld123!").await;
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
    let password = "HelloWorld123!";
    let _ = register_user(&app, email, password).await;
}

#[actix_rt::test]
async fn user_sign_in() {
    let app = spawn_app().await;
    let email = "annie@appflowy.io";
    let password = "HelloWorld123!";
    let _ = register_user(&app, email, password).await;
    let params = SignInParams {
        email: email.to_string(),
        password: password.to_string(),
    };
    let _ = app.sign_in(params).await.unwrap();
}

#[actix_rt::test]
#[should_panic]
async fn user_sign_out() {
    let app = spawn_app().await;
    let email = "annie@appflowy.io";
    let password = "HelloWorld123!";
    let _ = register_user(&app, email, password).await;

    let params = SignInParams {
        email: email.to_string(),
        password: password.to_string(),
    };
    let sign_in_resp = app.sign_in(params).await.unwrap();
    let token = sign_in_resp.token.clone();
    let user_token = UserToken {
        token: token.clone(),
    };
    app.sign_out(user_token).await;

    // user_detail will be empty because use was sign out.
    app.get_user_detail(&token).await;
}

#[actix_rt::test]
async fn user_get_detail() {
    let app = spawn_app().await;
    let sign_up_resp = sign_up_user(&app).await;
    log::info!("{:?}", app.get_user_detail(&sign_up_resp.token).await);
}

#[actix_rt::test]
async fn user_update_password() {
    let app = spawn_app().await;
    let email = "annie@appflowy.io";
    let password = "HelloWorld123!";
    let sign_up_resp = register_user(&app, email, password).await;

    let params = UpdateUserParams::new(&sign_up_resp.uid).password("Hello123!");
    app.update_user_detail(&sign_up_resp.token, params)
        .await
        .unwrap();

    let sign_in_params = SignInParams {
        email: email.to_string(),
        password: password.to_string(),
    };

    match app.sign_in(sign_in_params).await {
        Ok(_) => {},
        Err(e) => {
            assert_eq!(e.code, flowy_user::errors::ErrorCode::PasswordNotMatch);
        },
    }
}

#[actix_rt::test]
async fn user_update_name() {
    let app = spawn_app().await;
    let sign_up_resp = sign_up_user(&app).await;
    let name = "tom".to_string();
    let params = UpdateUserParams::new(&sign_up_resp.uid).name(&name);
    app.update_user_detail(&sign_up_resp.token, params)
        .await
        .unwrap();

    let user = app.get_user_detail(&sign_up_resp.token).await;
    assert_eq!(user.name, name);
}

#[actix_rt::test]
async fn user_update_email() {
    let app = spawn_app().await;
    let sign_up_resp = sign_up_user(&app).await;
    let email = "123@gmail.com".to_string();
    let params = UpdateUserParams::new(&sign_up_resp.uid).email(&email);
    app.update_user_detail(&sign_up_resp.token, params)
        .await
        .unwrap();

    let user = app.get_user_detail(&sign_up_resp.token).await;
    assert_eq!(user.email, email);
}

async fn sign_up_user(app: &TestApp) -> SignUpResponse {
    let email = "annie@appflowy.io";
    let password = "HelloWorld123!";
    let response = register_user(&app, email, password).await;
    response
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
