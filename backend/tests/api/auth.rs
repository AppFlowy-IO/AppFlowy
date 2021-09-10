use crate::helper::{spawn_server, TestServer};
use flowy_user::entities::{SignInParams, SignUpParams, SignUpResponse, UpdateUserParams};

#[actix_rt::test]
async fn user_register() {
    let app = spawn_server().await;
    let response = register_user(&app, "annie@appflowy.io", "HelloWorld123!").await;
    log::info!("{:?}", response);
}

#[actix_rt::test]
#[should_panic]
async fn user_sign_in_with_invalid_password() {
    let app = spawn_server().await;
    let email = "annie@appflowy.io";
    let password = "123";
    let _ = register_user(&app, email, password).await;
}

#[actix_rt::test]
#[should_panic]
async fn user_sign_in_with_invalid_email() {
    let app = spawn_server().await;
    let email = "annie@gmail@";
    let password = "HelloWorld123!";
    let _ = register_user(&app, email, password).await;
}

#[actix_rt::test]
async fn user_sign_in() {
    let app = spawn_server().await;
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
    let server = TestServer::new().await;
    server.sign_out().await;

    // user_detail will be empty because use was sign out.
    server.get_user_profile().await;
}

#[actix_rt::test]
async fn user_get_detail() {
    let server = TestServer::new().await;
    log::info!("{:?}", server.get_user_profile().await);
}

#[actix_rt::test]
async fn user_update_password() {
    let mut server = spawn_server().await;
    let email = "annie@appflowy.io";
    let password = "HelloWorld123!";
    let sign_up_resp = register_user(&server, email, password).await;

    let params = UpdateUserParams::new(&sign_up_resp.user_id).password("Hello123!");
    server.user_token = Some(sign_up_resp.token);

    server.update_user_profile(params).await.unwrap();

    let sign_in_params = SignInParams {
        email: email.to_string(),
        password: password.to_string(),
    };

    match server.sign_in(sign_in_params).await {
        Ok(_) => {},
        Err(e) => {
            assert_eq!(e.code, flowy_user::errors::ErrorCode::PasswordNotMatch);
        },
    }
}

#[actix_rt::test]
async fn user_update_name() {
    let server = TestServer::new().await;

    let name = "tom".to_string();
    let params = UpdateUserParams::new(&server.user_id()).name(&name);
    server.update_user_profile(params).await.unwrap();

    let user = server.get_user_profile().await;
    assert_eq!(user.name, name);
}

#[actix_rt::test]
async fn user_update_email() {
    let server = TestServer::new().await;
    let email = "123@gmail.com".to_string();
    let params = UpdateUserParams::new(server.user_id()).email(&email);
    server.update_user_profile(params).await.unwrap();

    let user = server.get_user_profile().await;
    assert_eq!(user.email, email);
}

async fn sign_up_user(server: &TestServer) -> SignUpResponse {
    let email = "annie@appflowy.io";
    let password = "HelloWorld123!";
    let response = register_user(server, email, password).await;
    response
}

async fn register_user(server: &TestServer, email: &str, password: &str) -> SignUpResponse {
    let params = SignUpParams {
        email: email.to_string(),
        name: "annie".to_string(),
        password: password.to_string(),
    };

    let response = server.register(params).await;
    response
}
