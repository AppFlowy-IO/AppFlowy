use crate::setup_log;
use flowy_ai::local_ai::chat::llm::LLMOllama;
use flowy_ai::local_ai::database::summary::DatabaseSummaryChain;
use std::collections::HashMap;

#[tokio::test]
async fn local_ollama_test_database_summary() {
  setup_log();

  let ollama = LLMOllama::default().with_model("llama3.1");
  let chain = DatabaseSummaryChain::new(ollama);

  let mut data = HashMap::new();
  data.insert("book name".to_string(), "Atomic Habits".to_string());
  data.insert("finish reading at".to_string(), "2023-02-10".to_string());
  data.insert(
    "notes".to_string(),
    "An atomic habit is a regular practice or routine that is not \
only small and easy to do but is also the source of incredible power; a \
component of the system of compound growth. Bad habits repeat themselves \
again and again not because you don't want to change, but because you \
have the wrong system for change. Changes that seem small and \
unimportant at first will compound into remarkable results if you're \
willing to stick with them for years"
      .to_string(),
  );

  let resp = chain.summarize(data).await.unwrap();
  dbg!(&resp);
}
