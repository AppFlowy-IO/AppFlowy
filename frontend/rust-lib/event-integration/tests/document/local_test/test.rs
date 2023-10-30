use collab_document::blocks::json_str_to_hashmap;
use event_integration::document::document_event::DocumentEventTest;
use event_integration::document::utils::*;
use flowy_document2::entities::*;
use flowy_document2::parser::parser_entities::{ConvertDocumentPayloadPB, ExportTypePB};
use serde_json::{json, Value};
use std::collections::HashMap;

#[tokio::test]
async fn get_document_event_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  let document = test.open_document(view.id).await;
  let document_data = document.data;
  assert!(!document_data.page_id.is_empty());
  assert!(document_data.blocks.len() > 1);
}

#[tokio::test]
async fn apply_document_event_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  let doc_id = view.id.clone();
  let document = test.open_document(doc_id.clone()).await;
  let block_count = document.data.blocks.len();
  let insert_action = gen_insert_block_action(document);
  let payload = ApplyActionPayloadPB {
    document_id: doc_id.clone(),
    actions: vec![insert_action],
  };
  test.apply_actions(payload).await;
  let document = test.open_document(doc_id).await;
  let document_data = document.data;
  let block_count_after = document_data.blocks.len();
  assert_eq!(block_count_after, block_count + 1);
}

#[tokio::test]
async fn undo_redo_event_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  let doc_id = view.id.clone();

  let document = test.open_document(doc_id.clone()).await;
  let insert_action = gen_insert_block_action(document);
  let payload = ApplyActionPayloadPB {
    document_id: doc_id.clone(),
    actions: vec![insert_action],
  };
  test.apply_actions(payload).await;
  let block_count_after_insert = test.open_document(doc_id.clone()).await.data.blocks.len();

  // undo insert action
  let can_undo = test.can_undo_redo(doc_id.clone()).await.can_undo;
  assert!(can_undo);
  test.undo(doc_id.clone()).await;
  let block_count_after_undo = test.open_document(doc_id.clone()).await.data.blocks.len();
  assert_eq!(block_count_after_undo, block_count_after_insert - 1);

  // redo insert action
  let can_redo = test.can_undo_redo(doc_id.clone()).await.can_redo;
  assert!(can_redo);
  test.redo(doc_id.clone()).await;
  let block_count_after_redo = test.open_document(doc_id.clone()).await.data.blocks.len();
  assert_eq!(block_count_after_redo, block_count_after_insert);
}

#[tokio::test]
async fn insert_text_block_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  let text = "Hello World";
  let block_id = test.insert_index(&view.id, text, 1, None).await;
  let block = test.get_block(&view.id, &block_id).await;
  assert!(block.is_some());
  let block = block.unwrap();
  assert!(block.external_id.is_some());
  let external_id = block.external_id.unwrap();
  let delta = test.get_block_text_delta(&view.id, &external_id).await;
  assert_eq!(delta.unwrap(), json!([{ "insert": text }]).to_string());
}

#[tokio::test]
async fn update_block_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  let block_id = test.insert_index(&view.id, "Hello World", 1, None).await;
  let data: HashMap<String, Value> = HashMap::from([
    (
      "bg_color".to_string(),
      serde_json::to_value("#000000").unwrap(),
    ),
    (
      "text_color".to_string(),
      serde_json::to_value("#ffffff").unwrap(),
    ),
  ]);
  test.update_data(&view.id, &block_id, data.clone()).await;
  let block = test.get_block(&view.id, &block_id).await;
  assert!(block.is_some());
  let block = block.unwrap();
  let block_data = json_str_to_hashmap(&block.data).ok().unwrap();
  assert_eq!(block_data, data);
}

#[tokio::test]
async fn apply_text_delta_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  let text = "Hello World";
  let block_id = test.insert_index(&view.id, text, 1, None).await;
  let update_delta = json!([{ "retain": 5 }, { "insert": "!" }]).to_string();
  test
    .apply_delta_for_block(&view.id, &block_id, update_delta)
    .await;
  let block = test.get_block(&view.id, &block_id).await;
  let text_id = block.unwrap().external_id.unwrap();
  let block_delta = test.get_block_text_delta(&view.id, &text_id).await;
  assert_eq!(
    block_delta.unwrap(),
    json!([{ "insert": "Hello! World" }]).to_string()
  );
}

macro_rules! generate_convert_document_test_cases {
  ($($json:ident, $text:ident, $html:ident),*) => {
    [
        $((ExportTypePB { json: $json, text: $text, html: $html }, ($json, $text, $html))),*
    ]
  };
}

#[tokio::test]
async fn convert_document_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;

  let test_cases = generate_convert_document_test_cases! {
    true, true, true,
    false, true, true,
    false, false, false
  };

  for (export_types, (json_assert, text_assert, html_assert)) in test_cases.iter() {
    let copy_payload = ConvertDocumentPayloadPB {
      document_id: view.id.to_string(),
      range: None,
      export_types: export_types.clone(),
    };
    let result = test.convert_document(copy_payload).await;
    assert_eq!(result.json.is_some(), *json_assert);
    assert_eq!(result.text.is_some(), *text_assert);
    assert_eq!(result.html.is_some(), *html_assert);
  }
}
