// use flowy_server::AppFlowyServer;
// use lib_infra::box_any::BoxAny;
//
// use crate::af_cloud_test::util::{af_cloud_server, af_cloud_sign_up_param, get_af_cloud_config};
//
// #[tokio::test]
// async fn sign_up_test() {
//   if let Some(config) = get_af_cloud_config() {
//     let server = af_cloud_server(config);
//     let user_service = server.user_service();
//
//     let params = af_cloud_sign_up_param();
//     let resp = user_service.sign_up(BoxAny::new(params)).await.unwrap();
//   }
// }
