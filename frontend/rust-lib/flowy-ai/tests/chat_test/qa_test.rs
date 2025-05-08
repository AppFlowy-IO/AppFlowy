use crate::{collect_stream, setup_log, TestContext};
use flowy_ai::local_ai::chat::chains::related_question_chain::RelatedQuestionChain;
use flowy_ai::local_ai::chat::llm::LLMOllama;
use flowy_ai_pub::cloud::{OutputLayout, ResponseFormat};
use flowy_ai_pub::entities::{SOURCE, SOURCE_ID, SOURCE_NAME};

#[tokio::test]
async fn local_ollama_test_simple_question() {
  let context = TestContext::new().unwrap();
  let mut chat = context.create_chat(vec![]).await;
  let stream = chat
    .stream_question("hello world", Default::default())
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  dbg!(result);
}

#[tokio::test]
async fn local_ollama_test_chat_with_multiple_docs_retrieve() {
  let context = TestContext::new().unwrap();
  let mut chat = context.create_chat(vec![]).await;
  let mut ids = vec![];

  for (doc, id) in  [("Rust is a multiplayer survival game developed by Facepunch Studios, first released in early access in December 2013 and fully launched in February 2018. It has since become one of the most popular games in the survival genre, known for its harsh environment, intricate crafting system, and player-driven dynamics. The game is available on Windows, macOS, and PlayStation, with a community-driven approach to updates and content additions.", uuid::Uuid::new_v4()),
        ("Rust is a modern, system-level programming language designed with a focus on performance, safety, and concurrency. It was created by Mozilla and first released in 2010, with its 1.0 version launched in 2015. Rust is known for providing the control and performance of languages like C and C++, but with built-in safety features that prevent common programming errors, such as memory leaks, data races, and buffer overflows.", uuid::Uuid::new_v4()),
        ("Rust as a Natural Process (Oxidation) refers to the chemical reaction that occurs when metals, primarily iron, come into contact with oxygen and moisture (water) over time, leading to the formation of iron oxide, commonly known as rust. This process is a form of oxidation, where a substance reacts with oxygen in the air or water, resulting in the degradation of the metal.", uuid::Uuid::new_v4())] {
        ids.push(id.to_string());
        chat.embed_paragraphs(&id.to_string(), vec![doc.to_string()]).await.unwrap();
    }
  chat.set_rag_ids(ids.clone());

  let all_docs = chat.get_all_embedded_documents().await.unwrap();
  assert_eq!(all_docs.len(), 3);
  assert_eq!(all_docs[0].fragments.len(), 1);
  assert_eq!(all_docs[1].fragments.len(), 1);
  assert_eq!(all_docs[2].fragments.len(), 1);

  let docs = chat
    .search("Rust is a multiplayer survival game", 5, ids.clone())
    .await
    .unwrap();
  assert_eq!(docs.len(), 1);

  let docs = chat
    .search(
      "chemical process of rust formation on metal",
      5,
      ids.clone(),
    )
    .await
    .unwrap();
  assert_eq!(docs.len(), 1);

  let stream = chat
    .stream_question("Rust is a multiplayer survival game", Default::default())
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  dbg!(&result);
  dbg!(&result.sources);

  assert!(!result.answer.is_empty());
  assert!(!result.sources.is_empty());
  assert!(result.sources[0].get(SOURCE_ID).unwrap().as_str().is_some());
  assert!(result.sources[0].get(SOURCE).unwrap().as_str().is_some());
  assert!(result.sources[0]
    .get(SOURCE_NAME)
    .unwrap()
    .as_str()
    .is_some());

  let stream = chat
    .stream_question("Japan ski resort", Default::default())
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  dbg!(&result);
}

#[tokio::test]
async fn local_ollama_test_chat_format() {
  let context = TestContext::new().unwrap();
  let mut chat = context.create_chat(vec![]).await;
  let mut format = ResponseFormat::new();
  format.output_layout = OutputLayout::SimpleTable;

  let stream = chat
    .stream_question("Compare rust and js", format)
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  dbg!(&result);
  assert!(!result.answer.is_empty());
}

#[tokio::test]
async fn local_ollama_test_chat_related_question() {
  setup_log();

  let ollama = LLMOllama::default().with_model("llama3.1");
  let chain = RelatedQuestionChain::new(ollama);
  let resp = chain
    .related_question("Compare rust with JS")
    .await
    .unwrap();

  dbg!(&resp);
  assert_eq!(resp.len(), 3);
}
