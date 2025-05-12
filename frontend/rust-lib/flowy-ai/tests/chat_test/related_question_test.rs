use crate::{collect_stream, load_asset_content, TestContext};
use uuid::Uuid;

#[tokio::test]
async fn local_ollama_test_context_related_questions() {
  let context = TestContext::new().unwrap();
  let mut chat = context.create_chat(vec![]).await;
  let stream = chat
    .stream_question("hello world", Default::default())
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  assert!(!result.answer.is_empty());

  let doc_id = Uuid::new_v4().to_string();
  let trip_docs = load_asset_content("japan_trip.md");
  chat.set_rag_ids(vec![doc_id.clone()]);
  chat
    .embed_paragraphs(&doc_id, vec![trip_docs])
    .await
    .unwrap();

  let stream = chat
    .stream_question("Compare rust with js", Default::default())
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  dbg!(&result.suggested_questions);
  assert_eq!(result.suggested_questions.len(), 3);
  assert!(!result.gen_related_question);

  // all suggested questions' object id should equal to doc_id
  for question in result.suggested_questions.iter() {
    assert_eq!(question.object_id, doc_id);
  }

  let stream = chat
    .stream_question(
      result.suggested_questions[0].content.as_str(),
      Default::default(),
    )
    .await
    .unwrap();
  let result = collect_stream(stream).await;
  dbg!(&result);
  assert!(result.suggested_questions.is_empty());
  assert!(result.gen_related_question);
}
