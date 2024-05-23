use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;

#[tokio::test]
async fn af_cloud_create_chat_message_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;

  let current_workspace = test.get_current_workspace().await;
  let view = test.create_chat(&current_workspace.id).await;
  let chat_id = view.id.clone();
  for i in 0..10 {
    test
      .send_message(&chat_id, format!("hello world {}", i))
      .await;
  }
  let all = test.load_message(&chat_id, 10, None, None).await;
  assert_eq!(all.messages.len(), 10);

  let list = test
    .load_message(&chat_id, 10, Some(all.messages[5].message_id), None)
    .await;
  assert_eq!(list.messages.len(), 4);
  assert_eq!(list.messages[0].content, "hello world 6");
  assert_eq!(list.messages[1].content, "hello world 7");
  assert_eq!(list.messages[2].content, "hello world 8");
  assert_eq!(list.messages[3].content, "hello world 9");

  let list = test
    .load_message(&chat_id, 10, None, Some(all.messages[3].message_id))
    .await;
  assert_eq!(list.messages.len(), 3);
  assert_eq!(list.messages[0].content, "hello world 0");
  assert_eq!(list.messages[1].content, "hello world 1");
  assert_eq!(list.messages[2].content, "hello world 2");
}
