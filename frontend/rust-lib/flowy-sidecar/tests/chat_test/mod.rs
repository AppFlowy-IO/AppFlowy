use crate::util::LocalAITest;

#[tokio::test]
async fn load_chat_model_test() {
  if let Ok(test) = LocalAITest::new() {
    let plugin_id = test.init_chat_plugin().await;
    let chat_id = uuid::Uuid::new_v4().to_string();
    let resp = test.send_message(&chat_id, plugin_id, "hello world").await;
    eprintln!("chat response: {:?}", resp);

    let embedding_plugin_id = test.init_embedding_plugin().await;
    let score = test.calculate_similarity(embedding_plugin_id, &resp, "Hello! How can I help you today? Is there something specific you would like to know or discuss").await;
    assert!(score > 0.8);
  }
}
