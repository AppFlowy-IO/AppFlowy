use flowy_ai::send_request;

#[tokio::test]
async fn test_send_request() {
  let result = send_request().await;
  assert!(result.is_ok());
}
