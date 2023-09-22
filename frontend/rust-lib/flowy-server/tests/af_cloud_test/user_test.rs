use flowy_server::AppFlowyServer;
use flowy_user_deps::entities::{AuthType, SignUpParams};
use lib_infra::box_any::BoxAny;

use crate::af_cloud_test::util::{af_cloud_server, get_af_cloud_config};

//
#[tokio::test]
async fn sign_up_test() {
  if let Some(config) = get_af_cloud_config() {
    let server = af_cloud_server(config);
    let user_service = server.user_service();

    let name = uuid::Uuid::new_v4().to_string();
    let device_id = name.clone();
    let email = format!("{}@test.com", name);
    let params = SignUpParams {
      email,
      name,
      password: "Hello!123".to_string(),
      auth_type: AuthType::AFCloud,
      device_id,
    };
    let resp = user_service.sign_up(BoxAny::new(params)).await.unwrap();
  }
}
