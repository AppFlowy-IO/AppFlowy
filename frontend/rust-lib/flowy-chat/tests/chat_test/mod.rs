use crate::util::LocalAITest;
use tokio_stream::StreamExt;

#[tokio::test]
async fn load_chat_model_test() {
  if let Ok(test) = LocalAITest::new() {
    let plugin_id = test.init_chat_plugin().await;
    let chat_id = uuid::Uuid::new_v4().to_string();
    let resp = test
      .send_chat_message(&chat_id, plugin_id, "hello world")
      .await;
    eprintln!("chat response: {:?}", resp);

    let embedding_plugin_id = test.init_embedding_plugin().await;
    let score = test.calculate_similarity(embedding_plugin_id, &resp, "Hello! How can I help you today? Is there something specific you would like to know or discuss").await;
    assert!(score > 0.8);

    // let questions = test.related_question(&chat_id, plugin_id).await;
    // assert_eq!(questions.len(), 3);
    // eprintln!("related questions: {:?}", questions);
  }
}
#[tokio::test]
async fn stream_local_model_test() {
  if let Ok(test) = LocalAITest::new() {
    let plugin_id = test.init_chat_plugin().await;
    let chat_id = uuid::Uuid::new_v4().to_string();

    let mut resp = test
      .stream_chat_message(&chat_id, plugin_id, "hello world")
      .await;
    let mut list = vec![];
    while let Some(s) = resp.next().await {
      list.push(s.unwrap());
    }

    let answer = list.join("");
    eprintln!("chat response: {:?}", answer);
    tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;
  }
}
