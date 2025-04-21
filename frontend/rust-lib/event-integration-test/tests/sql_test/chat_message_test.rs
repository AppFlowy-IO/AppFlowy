use event_integration_test::user_event::use_localhost_af_cloud;
use event_integration_test::EventIntegrationTest;
use flowy_ai_pub::cloud::MessageCursor;
use flowy_ai_pub::persistence::{
  select_answer_where_match_reply_message_id, select_chat_messages, select_message,
  select_message_content, total_message_count, upsert_chat_messages, ChatMessageTable,
};
use uuid::Uuid;

#[tokio::test]
async fn chat_message_table_insert_select_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();
  let message_id_1 = 1000;
  let message_id_2 = 2000;

  // Create test messages
  let messages = vec![
    ChatMessageTable {
      message_id: message_id_1,
      chat_id: chat_id.clone(),
      content: "Hello, this is a test message".to_string(),
      created_at: 1625097600, // 2021-07-01
      author_type: 1,         // User
      author_id: "user_1".to_string(),
      reply_message_id: None,
      metadata: None,
      is_sync: false,
    },
    ChatMessageTable {
      message_id: message_id_2,
      chat_id: chat_id.clone(),
      content: "This is a reply to the test message".to_string(),
      created_at: 1625097700, // 2021-07-01, 100 seconds later
      author_type: 0,         // AI
      author_id: "ai".to_string(),
      reply_message_id: Some(message_id_1),
      metadata: Some(r#"{"source": "test"}"#.to_string()),
      is_sync: false,
    },
  ];

  // Test insert_chat_messages
  let result = upsert_chat_messages(db_conn, &messages);
  assert!(
    result.is_ok(),
    "Failed to insert chat messages: {:?}",
    result
  );

  // Test select_chat_messages
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let messages_result =
    select_chat_messages(db_conn, &chat_id, 10, MessageCursor::Offset(0)).unwrap();

  assert_eq!(messages_result.messages.len(), 2);
  assert_eq!(messages_result.total_count, 2);
  assert!(!messages_result.has_more);

  // Verify the content of the returned messages
  let first_message = messages_result
    .messages
    .iter()
    .find(|m| m.message_id == message_id_1)
    .unwrap();
  assert_eq!(first_message.content, "Hello, this is a test message");
  assert_eq!(first_message.author_type, 1);

  let second_message = messages_result
    .messages
    .iter()
    .find(|m| m.message_id == message_id_2)
    .unwrap();
  assert_eq!(
    second_message.content,
    "This is a reply to the test message"
  );
  assert_eq!(second_message.reply_message_id, Some(message_id_1));
}

#[tokio::test]
async fn chat_message_table_cursor_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();

  // Create multiple test messages with sequential IDs
  let mut messages = Vec::new();
  for i in 1..6 {
    messages.push(ChatMessageTable {
      message_id: i * 1000,
      chat_id: chat_id.clone(),
      content: format!("Message {}", i),
      created_at: 1625097600 + (i * 100), // Increasing timestamps
      author_type: 1,                     // User
      author_id: "user_1".to_string(),
      reply_message_id: None,
      metadata: None,
      is_sync: false,
    });
  }

  // Insert messages
  upsert_chat_messages(db_conn, &messages).unwrap();

  // Test MessageCursor::Offset
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result_offset = select_chat_messages(
    db_conn,
    &chat_id,
    2, // Limit to 2 messages
    MessageCursor::Offset(0),
  )
  .unwrap();

  assert_eq!(result_offset.messages.len(), 2);
  assert!(result_offset.has_more);

  // Test MessageCursor::AfterMessageId
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result_after = select_chat_messages(
    db_conn,
    &chat_id,
    3, // Limit to 3 messages
    MessageCursor::AfterMessageId(2000),
  )
  .unwrap();

  assert_eq!(result_after.messages.len(), 3); // Should get message IDs 3000, 4000, 5000
  assert!(result_after.messages.iter().all(|m| m.message_id > 2000));

  // Test MessageCursor::BeforeMessageId
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result_before = select_chat_messages(
    db_conn,
    &chat_id,
    2, // Limit to 2 messages
    MessageCursor::BeforeMessageId(4000),
  )
  .unwrap();

  assert_eq!(result_before.messages.len(), 2); // Should get message IDs 1000, 2000, 3000
  assert!(result_before.messages.iter().all(|m| m.message_id < 4000));
}

#[tokio::test]
async fn chat_message_total_count_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();

  // Create test messages
  let messages = vec![
    ChatMessageTable {
      message_id: 1001,
      chat_id: chat_id.clone(),
      content: "Message 1".to_string(),
      created_at: 1625097600,
      author_type: 1,
      author_id: "user_1".to_string(),
      reply_message_id: None,
      metadata: None,
      is_sync: false,
    },
    ChatMessageTable {
      message_id: 1002,
      chat_id: chat_id.clone(),
      content: "Message 2".to_string(),
      created_at: 1625097700,
      author_type: 0,
      author_id: "ai".to_string(),
      reply_message_id: None,
      metadata: None,
      is_sync: false,
    },
  ];

  // Insert messages
  upsert_chat_messages(db_conn, &messages).unwrap();

  // Test total_message_count
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let count = total_message_count(db_conn, &chat_id).unwrap();
  assert_eq!(count, 2);

  // Add one more message
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let additional_message = ChatMessageTable {
    message_id: 1003,
    chat_id: chat_id.clone(),
    content: "Message 3".to_string(),
    created_at: 1625097800,
    author_type: 1,
    author_id: "user_1".to_string(),
    reply_message_id: None,
    metadata: None,
    is_sync: false,
  };

  upsert_chat_messages(db_conn, &[additional_message]).unwrap();

  // Verify count increased
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let updated_count = total_message_count(db_conn, &chat_id).unwrap();
  assert_eq!(updated_count, 3);

  // Test count for non-existent chat
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let empty_count = total_message_count(db_conn, "non_existent_chat").unwrap();
  assert_eq!(empty_count, 0);
}

#[tokio::test]
async fn chat_message_select_message_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();
  let message_id = 2001;

  // Create test message
  let message = ChatMessageTable {
    message_id,
    chat_id: chat_id.clone(),
    content: "This is a test message for select_message".to_string(),
    created_at: 1625097600,
    author_type: 1,
    author_id: "user_1".to_string(),
    reply_message_id: None,
    metadata: Some(r#"{"test_key": "test_value"}"#.to_string()),
    is_sync: false,
  };

  // Insert message
  upsert_chat_messages(db_conn, &[message]).unwrap();

  // Test select_message
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result = select_message(db_conn, message_id).unwrap();
  assert!(result.is_some());

  let retrieved_message = result.unwrap();
  assert_eq!(retrieved_message.message_id, message_id);
  assert_eq!(retrieved_message.chat_id, chat_id);
  assert_eq!(
    retrieved_message.content,
    "This is a test message for select_message"
  );
  assert_eq!(retrieved_message.author_id, "user_1");
  assert_eq!(
    retrieved_message.metadata,
    Some(r#"{"test_key": "test_value"}"#.to_string())
  );

  // Test select_message with non-existent ID
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let non_existent = select_message(db_conn, 9999).unwrap();
  assert!(non_existent.is_none());
}

#[tokio::test]
async fn chat_message_select_content_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();
  let message_id = 3001;
  let message_content = "This is the content to retrieve";

  // Create test message
  let message = ChatMessageTable {
    message_id,
    chat_id: chat_id.clone(),
    content: message_content.to_string(),
    created_at: 1625097600,
    author_type: 1,
    author_id: "user_1".to_string(),
    reply_message_id: None,
    metadata: None,
    is_sync: false,
  };

  // Insert message
  upsert_chat_messages(db_conn, &[message]).unwrap();

  // Test select_message_content
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let content = select_message_content(db_conn, message_id).unwrap();
  assert!(content.is_some());
  assert_eq!(content.unwrap(), message_content);

  // Test with non-existent message
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let no_content = select_message_content(db_conn, 9999).unwrap();
  assert!(no_content.is_none());
}

#[tokio::test]
async fn chat_message_reply_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();
  let question_id = 4001;
  let answer_id = 4002;

  // Create question and answer messages
  let question = ChatMessageTable {
    message_id: question_id,
    chat_id: chat_id.clone(),
    content: "What is the question?".to_string(),
    created_at: 1625097600,
    author_type: 1, // User
    author_id: "user_1".to_string(),
    reply_message_id: None,
    metadata: None,
    is_sync: false,
  };

  let answer = ChatMessageTable {
    message_id: answer_id,
    chat_id: chat_id.clone(),
    content: "This is the answer".to_string(),
    created_at: 1625097700,
    author_type: 0, // AI
    author_id: "ai".to_string(),
    reply_message_id: Some(question_id), // Link to question
    metadata: None,
    is_sync: false,
  };

  // Insert messages
  upsert_chat_messages(db_conn, &[question, answer]).unwrap();

  // Test select_message_where_match_reply_message_id
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result = select_answer_where_match_reply_message_id(db_conn, &chat_id, question_id).unwrap();

  assert!(result.is_some());
  let reply = result.unwrap();
  assert_eq!(reply.message_id, answer_id);
  assert_eq!(reply.content, "This is the answer");
  assert_eq!(reply.reply_message_id, Some(question_id));

  // Test with non-existent reply relation
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let no_reply = select_answer_where_match_reply_message_id(
    db_conn, &chat_id, 9999, // Non-existent question ID
  )
  .unwrap();

  assert!(no_reply.is_none());

  // Test with wrong chat_id
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let wrong_chat =
    select_answer_where_match_reply_message_id(db_conn, "wrong_chat_id", question_id).unwrap();

  assert!(wrong_chat.is_none());
}

#[tokio::test]
async fn chat_message_upsert_test() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();
  let message_id = 5001;

  // Create initial message
  let message = ChatMessageTable {
    message_id,
    chat_id: chat_id.clone(),
    content: "Original content".to_string(),
    created_at: 1625097600,
    author_type: 1,
    author_id: "user_1".to_string(),
    reply_message_id: None,
    metadata: None,
    is_sync: false,
  };

  // Insert message
  upsert_chat_messages(db_conn, &[message]).unwrap();

  // Check original content
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let original = select_message(db_conn, message_id).unwrap().unwrap();
  assert_eq!(original.content, "Original content");

  // Create updated message with same ID but different content
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let updated_message = ChatMessageTable {
    message_id, // Same ID
    chat_id: chat_id.clone(),
    content: "Updated content".to_string(), // New content
    created_at: 1625097700,                 // Updated timestamp
    author_type: 1,
    author_id: "user_1".to_string(),
    reply_message_id: Some(1000), // Added reply ID
    metadata: Some(r#"{"updated": true}"#.to_string()),
    is_sync: false,
  };

  // Upsert message
  upsert_chat_messages(db_conn, &[updated_message]).unwrap();

  // Verify update
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result = select_message(db_conn, message_id).unwrap().unwrap();
  assert_eq!(result.content, "Updated content");
  assert_eq!(result.created_at, 1625097700);
  assert_eq!(result.reply_message_id, Some(1000));
  assert_eq!(result.metadata, Some(r#"{"updated": true}"#.to_string()));

  // Count should still be 1 (update, not insert)
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let count = total_message_count(db_conn, &chat_id).unwrap();
  assert_eq!(count, 1);
}

#[tokio::test]
async fn chat_message_select_with_large_dataset() {
  use_localhost_af_cloud().await;
  let test = EventIntegrationTest::new().await;
  test.sign_up_as_anon().await;

  let uid = test.user_manager.get_anon_user().await.unwrap().id;
  let db_conn = test.user_manager.db_connection(uid).unwrap();

  let chat_id = Uuid::new_v4().to_string();

  // Create 100 test messages with sequential IDs
  let mut messages = Vec::new();
  for i in 1..=100 {
    messages.push(ChatMessageTable {
      message_id: i * 100,
      chat_id: chat_id.clone(),
      content: format!("Message {}", i),
      created_at: 1625097600 + (i * 10), // Increasing timestamps
      author_type: if i % 2 == 0 { 0 } else { 1 }, // Alternate between AI and User
      author_id: if i % 2 == 0 {
        "ai".to_string()
      } else {
        "user_1".to_string()
      },
      reply_message_id: if i > 1 && i % 2 == 0 {
        Some((i - 1) * 100)
      } else {
        None
      }, // Even messages reply to previous message
      metadata: if i % 5 == 0 {
        Some(format!(r#"{{"index": {}}}"#, i))
      } else {
        None
      },
      is_sync: false,
    });
  }

  // Insert all 100 messages
  upsert_chat_messages(db_conn, &messages).unwrap();

  // Verify total count
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let count = total_message_count(db_conn, &chat_id).unwrap();
  assert_eq!(count, 100, "Should have 100 messages in the database");

  // Test 1: MessageCursor::Offset with small page size
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let page_size = 10;
  let result_offset =
    select_chat_messages(db_conn, &chat_id, page_size, MessageCursor::Offset(0)).unwrap();

  assert_eq!(
    result_offset.messages.len(),
    page_size as usize,
    "Should return exactly {page_size} messages"
  );
  assert!(
    result_offset.has_more,
    "Should have more messages available"
  );
  assert_eq!(result_offset.total_count, 100, "Total count should be 100");

  // Test 2: Pagination with offset
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result_page2 = select_chat_messages(
    db_conn,
    &chat_id,
    page_size,
    MessageCursor::Offset(page_size),
  )
  .unwrap();

  assert_eq!(result_page2.messages.len(), page_size as usize);
  assert!(
    result_page2.messages[0].message_id != result_offset.messages[0].message_id,
    "Second page should have different messages than first page"
  );

  // Test 3: MessageCursor::AfterMessageId (forward pagination)
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let middle_message_id = 5000; // Message ID from the middle
  let result_after = select_chat_messages(
    db_conn,
    &chat_id,
    page_size,
    MessageCursor::AfterMessageId(middle_message_id),
  )
  .unwrap();

  assert_eq!(result_after.messages.len(), page_size as usize);
  assert!(
    result_after
      .messages
      .iter()
      .all(|m| m.message_id > middle_message_id),
    "All messages should have ID greater than the cursor"
  );

  // Test 4: MessageCursor::BeforeMessageId (backward pagination)
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result_before = select_chat_messages(
    db_conn,
    &chat_id,
    page_size,
    MessageCursor::BeforeMessageId(middle_message_id),
  )
  .unwrap();

  assert_eq!(result_before.messages.len(), page_size as usize);
  assert!(
    result_before
      .messages
      .iter()
      .all(|m| m.message_id < middle_message_id),
    "All messages should have ID less than the cursor"
  );

  // Test 5: Large page size (retrieve all)
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result_all = select_chat_messages(
    db_conn,
    &chat_id,
    200, // More than we have
    MessageCursor::Offset(0),
  )
  .unwrap();

  assert_eq!(
    result_all.messages.len(),
    100,
    "Should return all 100 messages"
  );
  assert!(!result_all.has_more, "Should not have more messages");

  // Test 6: Empty result when using out of range cursor
  let db_conn = test.user_manager.db_connection(uid).unwrap();
  let result_out_of_range = select_chat_messages(
    db_conn,
    &chat_id,
    page_size,
    MessageCursor::AfterMessageId(10000), // After the last message
  )
  .unwrap();

  assert_eq!(
    result_out_of_range.messages.len(),
    0,
    "Should return no messages"
  );
  assert!(
    !result_out_of_range.has_more,
    "Should not have more messages"
  );
}
