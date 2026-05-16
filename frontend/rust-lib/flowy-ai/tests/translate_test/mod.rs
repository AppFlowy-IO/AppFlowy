use crate::setup_log;
use flowy_ai::local_ai::chat::llm::LLMOllama;
use flowy_ai::local_ai::database::translate::DatabaseTranslateChain;
use flowy_ai_pub::cloud::ai_dto::TranslateRowData;
use flowy_database_pub::cloud::TranslateItem;

#[tokio::test]
async fn local_ollama_test_database_translate() {
  setup_log();

  let ollama = LLMOllama::default().with_model("llama3.1");
  let chain = DatabaseTranslateChain::new(ollama);

  let data = TranslateRowData {
    cells: vec![
      TranslateItem {
        title: "name".to_string(),
        content: "Jask".to_string(),
      },
      TranslateItem {
        title: "age".to_string(),
        content: "25".to_string(),
      },
      TranslateItem {
        title: "city".to_string(),
        content: "New York".to_string(),
      },
    ],
    language: "french".to_string(),
    include_header: false,
  };
  let resp = chain.translate(data).await.unwrap();
  dbg!(&resp);
  assert!(!resp.items.is_empty());
}
