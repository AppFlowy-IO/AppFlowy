use crate::document::generate_random_string;
use collab_document::blocks::json_str_to_hashmap;
use event_integration_test::document::document_event::DocumentEventTest;
use event_integration_test::document::utils::*;
use flowy_document::entities::*;
use flowy_document::parser::parser_entities::{
  ConvertDataToJsonPayloadPB, ConvertDocumentPayloadPB, InputType, NestedBlock, ParseTypePB,
};
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
async fn get_encoded_collab_event_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;
  let doc_id = view.id.clone();
  let encoded_v1 = test.get_encoded_collab(&doc_id).await;
  assert!(!encoded_v1.doc_state.is_empty());
  assert!(!encoded_v1.state_vector.is_empty());
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
  let text_id = test.get_text_id(&view.id, &block_id).await.unwrap();
  let delta = test.get_delta(&view.id, &text_id).await;
  assert_eq!(delta.unwrap(), json!([{ "insert": text }]).to_string());
}
#[tokio::test]
async fn document_size_test() {
  let test = DocumentEventTest::new().await;
  let view = test.create_document().await;

  let max_size = 1024 * 1024; // 1mb
  let total_string_size = 500 * 1024; // 500kb
  let string_size = 1000;
  let iter_len = total_string_size / string_size;
  for _ in 0..iter_len {
    let s = generate_random_string(string_size);
    test.insert_index(&view.id, &s, 1, None).await;
  }

  let encoded_v1 = test.get_encoded_v1(&view.id).await;
  if encoded_v1.doc_state.len() > max_size {
    panic!(
      "The document size is too large. {}",
      encoded_v1.doc_state.len()
    );
  }
  println!("The document size is {}", encoded_v1.doc_state.len());
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
  let text_id = test.get_text_id(&view.id, &block_id).await.unwrap();
  let delta = test.get_delta(&view.id, &text_id).await;
  assert_eq!(
    delta.unwrap(),
    json!([{ "insert": "Hello World" }]).to_string()
  );
}

macro_rules! generate_convert_document_test_cases {
  ($($json:ident, $text:ident, $html:ident),*) => {
    [
        $((ParseTypePB { json: $json, text: $text, html: $html }, ($json, $text, $html))),*
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
      parse_types: export_types.clone(),
    };
    let result = test.convert_document(copy_payload).await;
    assert_eq!(result.json.is_some(), *json_assert);
    assert_eq!(result.text.is_some(), *text_assert);
    assert_eq!(result.html.is_some(), *html_assert);
  }
}

/// test convert data to json
/// - input html: <p>Hello</p><p> World!</p>
/// - input plain text: Hello World!
/// - output json: { "type": "page", "data": {}, "children": [{ "type": "paragraph", "children": [], "data": { "delta": [{ "insert": "Hello" }] } }, { "type": "paragraph", "children": [], "data": { "delta": [{ "insert": " World!" }] } }] }
#[tokio::test]
async fn convert_data_to_json_test() {
  let test = DocumentEventTest::new().await;
  let _ = test.create_document().await;

  let html = r#"<p>Hello</p><p>World!</p>"#;
  let payload = ConvertDataToJsonPayloadPB {
    data: html.to_string(),
    input_type: InputType::Html,
  };
  let result = test.convert_data_to_json(payload).await;
  let expect_json = json!({
    "type": "page",
    "data": {},
    "children": [{
      "type": "paragraph",
      "children": [],
      "data": {
        "delta": [{ "insert": "Hello" }]
      }
    }, {
      "type": "paragraph",
      "children": [],
      "data": {
        "delta": [{ "insert": "World!" }]
      }
    }]
  });

  let expect_json = serde_json::from_value::<NestedBlock>(expect_json).unwrap();
  assert!(serde_json::from_str::<NestedBlock>(&result.json)
    .unwrap()
    .eq(&expect_json));

  let plain_text = "Hello\nWorld!";
  let payload = ConvertDataToJsonPayloadPB {
    data: plain_text.to_string(),
    input_type: InputType::PlainText,
  };
  let result = test.convert_data_to_json(payload).await;

  assert!(serde_json::from_str::<NestedBlock>(&result.json)
    .unwrap()
    .eq(&expect_json));
}
