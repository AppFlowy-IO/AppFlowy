use flowy_ai::send_request;

#[tokio::test]
async fn test_send_request() {
  let content_type = "blog post"; // replace this with actual user input
  let topic = "Plan a trip to Paris"; // replace this with actual user input
  let prompt = format!("Write a {} about {}", content_type, topic);
  let result = send_request(prompt).await;
  assert!(result.is_ok());
}
