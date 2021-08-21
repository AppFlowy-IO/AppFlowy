use flowy_user::prelude::*;

#[tokio::test]
async fn user_register_test() {
    let server = UserServerImpl {};

    let params = SignUpParams {
        email: "annie@appflowy.io".to_string(),
        name: "annie".to_string(),
        password: "123".to_string(),
    };
    let result = server.sign_up(params).await.unwrap();
}
