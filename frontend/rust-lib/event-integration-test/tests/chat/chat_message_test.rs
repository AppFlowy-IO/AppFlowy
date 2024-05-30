use crate::util::receive_with_timeout;
use event_integration_test::user_event::user_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_chat::entities::{ChatMessageListPB, ChatMessageTypePB};
use flowy_chat::notification::ChatNotification;

use std::time::Duration;

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
      .send_message(
        &chat_id,
        format!("hello world {}", i),
        ChatMessageTypePB::System,
      )
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

#[tokio::test]
async fn af_cloud_load_remote_system_message_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;

  let current_workspace = test.get_current_workspace().await;
  let view = test.create_chat(&current_workspace.id).await;
  let chat_id = view.id.clone();

  let chat_service = test.server_provider.get_server().unwrap().chat_service();
  for i in 0..10 {
    chat_service
      .send_chat_message(
        &current_workspace.id,
        &chat_id,
        &format!("hello server {}", i),
      )
      .await
      .unwrap();
  }
  let rx = test
    .notification_sender
    .subscribe::<ChatMessageListPB>(&chat_id, ChatNotification::DidLoadChatMessage);

  // Previous messages were created by the server, so there are no messages in the local cache.
  // It will try to load messages in the background.
  let all = test.load_message(&chat_id, 5, None, None).await;
  assert!(all.messages.is_empty());

  // Wait for the messages to be loaded.
  let next_back_five = receive_with_timeout(rx, Duration::from_secs(30))
    .await
    .unwrap();
  assert_eq!(next_back_five.messages.len(), 5);
  assert!(next_back_five.has_more);
  assert_eq!(next_back_five.total, 10);
  assert_eq!(next_back_five.messages[0].content, "hello server 5");
  assert_eq!(next_back_five.messages[1].content, "hello server 6");
  assert_eq!(next_back_five.messages[2].content, "hello server 7");
  assert_eq!(next_back_five.messages[3].content, "hello server 8");
  assert_eq!(next_back_five.messages[4].content, "hello server 9");

  // Load first five messages
  let rx = test
    .notification_sender
    .subscribe::<ChatMessageListPB>(&chat_id, ChatNotification::DidLoadChatMessage);
  test
    .load_message(
      &chat_id,
      5,
      None,
      Some(next_back_five.messages[0].message_id),
    )
    .await;
  let first_five_messages = receive_with_timeout(rx, Duration::from_secs(30))
    .await
    .unwrap();
  assert!(!first_five_messages.has_more);
  assert_eq!(first_five_messages.messages[0].content, "hello server 0");
  assert_eq!(first_five_messages.messages[1].content, "hello server 1");
  assert_eq!(first_five_messages.messages[2].content, "hello server 2");
  assert_eq!(first_five_messages.messages[3].content, "hello server 3");
  assert_eq!(first_five_messages.messages[4].content, "hello server 4");
}

#[tokio::test]
async fn af_cloud_load_remote_user_message_test() {
  user_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.af_cloud_sign_up().await;

  let current_workspace = test.get_current_workspace().await;
  let view = test.create_chat(&current_workspace.id).await;
  let chat_id = view.id.clone();
  test
    .send_message(&chat_id, "hello world", ChatMessageTypePB::User)
    .await;

  let all = test.load_message(&chat_id, 5, None, None).await;
  assert_eq!(all.messages.len(), 2);
  // 2 means User
  assert_eq!(all.messages[0].author_type, 1);
  // 3 means AI
  assert_eq!(all.messages[1].author_type, 3);
  // The message ID is incremented by 1.
  assert_eq!(all.messages[0].message_id + 1, all.messages[1].message_id);
}
