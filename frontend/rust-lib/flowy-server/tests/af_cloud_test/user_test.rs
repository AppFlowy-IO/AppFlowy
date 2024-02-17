use flowy_server::AppFlowyServer;
use flowy_user_pub::entities::AuthResponse;
use lib_infra::box_any::BoxAny;

use crate::af_cloud_test::util::{
  af_cloud_server, af_cloud_sign_up_param, generate_test_email, get_af_cloud_config,
};

#[tokio::test]
async fn sign_up_test() {
  if let Some(config) = get_af_cloud_config() {
    let server = af_cloud_server(config.clone());
    let user_service = server.user_service();
    let email = generate_test_email();
    let params = af_cloud_sign_up_param(&email, &config).await;
    let resp: AuthResponse = user_service.sign_up(BoxAny::new(params)).await.unwrap();
    assert_eq!(resp.email.unwrap(), email);
    assert!(resp.is_new_user);
    assert_eq!(resp.user_workspaces.len(), 1);
  }
}
