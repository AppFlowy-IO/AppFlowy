use std::{collections::HashMap, vec};

use collab_document::blocks::{Block, BlockAction, BlockActionPayload, BlockActionType};
use collab_document::document_data::{default_document_data, PARAGRAPH_BLOCK_TYPE};
use serde_json::{json, to_value, Value};

use crate::document::util::{gen_document_id, gen_id, DocumentTest};

#[tokio::test]
async fn restore_document() {
  let test = DocumentTest::new();

  // create a document
  let doc_id: String = gen_document_id();
  let data = default_document_data();
  let uid = test.user.user_id().unwrap();
  let document_a = test
    .create_document(uid, &doc_id, Some(data.clone()))
    .await
    .unwrap();
  let data_a = document_a.lock().get_document_data().unwrap();
  assert_eq!(data_a, data);

  let data_b = test
    .get_document(&doc_id)
    .await
    .unwrap()
    .lock()
    .get_document_data()
    .unwrap();
  // close a document
  _ = test.close_document(&doc_id);
  assert_eq!(data_b, data);

  // restore
  _ = test.create_document(uid, &doc_id, Some(data.clone())).await;
  // open a document
  let data_b = test
    .get_document(&doc_id)
    .await
    .unwrap()
    .lock()
    .get_document_data()
    .unwrap();
  // close a document
  _ = test.close_document(&doc_id);

  assert_eq!(data_b, data);
}

#[tokio::test]
async fn document_apply_insert_action() {
  let test = DocumentTest::new();
  let uid = test.user.user_id().unwrap();
  let doc_id: String = gen_document_id();
  let data = default_document_data();

  // create a document
  _ = test.create_document(uid, &doc_id, Some(data.clone())).await;

  // open a document
  let document = test.get_document(&doc_id).await.unwrap();
  let page_block = document.lock().get_block(&data.page_id).unwrap();

  // insert a text block
  let text_block = Block {
    id: gen_id(),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: page_block.id,
    children: gen_id(),
    external_id: None,
    external_type: None,
    data: HashMap::new(),
  };
  let insert_text_action = BlockAction {
    action: BlockActionType::Insert,
    payload: BlockActionPayload {
      block: text_block,
      parent_id: None,
      prev_id: None,
    },
  };
  document.lock().apply_action(vec![insert_text_action]);
  let data_a = document.lock().get_document_data().unwrap();
  // close the original document
  _ = test.close_document(&doc_id);

  // re-open the document
  let data_b = test
    .get_document(&doc_id)
    .await
    .unwrap()
    .lock()
    .get_document_data()
    .unwrap();
  // close a document
  _ = test.close_document(&doc_id);

  assert_eq!(data_b, data_a);
}

#[tokio::test]
async fn document_apply_update_page_action() {
  let test = DocumentTest::new();
  let doc_id: String = gen_document_id();
  let uid = test.user.user_id().unwrap();
  let data = default_document_data();

  // create a document
  _ = test.create_document(uid, &doc_id, Some(data.clone())).await;

  // open a document
  let document = test.get_document(&doc_id).await.unwrap();
  let page_block = document.lock().get_block(&data.page_id).unwrap();

  let mut page_block_clone = page_block;
  page_block_clone.data = HashMap::new();
  page_block_clone.data.insert(
    "delta".to_string(),
    to_value(json!([{"insert": "Hello World!"}])).unwrap(),
  );
  let action = BlockAction {
    action: BlockActionType::Update,
    payload: BlockActionPayload {
      block: page_block_clone,
      parent_id: None,
      prev_id: None,
    },
  };
  let actions = vec![action];
  tracing::trace!("{:?}", &actions);
  document.lock().apply_action(actions);
  let page_block_old = document.lock().get_block(&data.page_id).unwrap();
  _ = test.close_document(&doc_id);

  // re-open the document
  let document = test.get_document(&doc_id).await.unwrap();
  let page_block_new = document.lock().get_block(&data.page_id).unwrap();
  assert_eq!(page_block_old, page_block_new);
  assert!(page_block_new.data.contains_key("delta"));
}

#[tokio::test]
async fn document_apply_update_action() {
  let test = DocumentTest::new();
  let uid = test.user.user_id().unwrap();
  let doc_id: String = gen_document_id();
  let data = default_document_data();

  // create a document
  _ = test.create_document(uid, &doc_id, Some(data.clone())).await;

  // open a document
  let document = test.get_document(&doc_id).await.unwrap();
  let page_block = document.lock().get_block(&data.page_id).unwrap();

  // insert a text block
  let text_block_id = gen_id();
  let text_block = Block {
    id: text_block_id.clone(),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: page_block.id,
    children: gen_id(),
    external_id: None,
    external_type: None,
    data: HashMap::new(),
  };
  let insert_text_action = BlockAction {
    action: BlockActionType::Insert,
    payload: BlockActionPayload {
      block: text_block,
      parent_id: None,
      prev_id: None,
    },
  };
  document.lock().apply_action(vec![insert_text_action]);

  // update the text block
  let existing_text_block = document.lock().get_block(&text_block_id).unwrap();
  let mut updated_text_block_data = HashMap::new();
  updated_text_block_data.insert("delta".to_string(), Value::String("delta".to_string()));
  let updated_text_block = Block {
    id: existing_text_block.id,
    ty: existing_text_block.ty,
    parent: existing_text_block.parent,
    children: existing_text_block.children,
    external_id: None,
    external_type: None,
    data: updated_text_block_data.clone(),
  };
  let update_text_action = BlockAction {
    action: BlockActionType::Update,
    payload: BlockActionPayload {
      block: updated_text_block,
      parent_id: None,
      prev_id: None,
    },
  };
  document.lock().apply_action(vec![update_text_action]);
  // close the original document
  _ = test.close_document(&doc_id);

  // re-open the document
  let document = test.get_document(&doc_id).await.unwrap();
  let block = document.lock().get_block(&text_block_id).unwrap();
  assert_eq!(block.data, updated_text_block_data);
  // close a document
  _ = test.close_document(&doc_id);
}
