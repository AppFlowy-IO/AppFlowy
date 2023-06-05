use std::{collections::HashMap, sync::Arc, vec};

use collab_document::blocks::{Block, BlockAction, BlockActionPayload, BlockActionType};
use nanoid::nanoid;
use serde_json::{json, to_value, Value};

use flowy_document2::document_block_keys::PARAGRAPH_BLOCK_TYPE;
use flowy_document2::document_data::default_document_data;
use flowy_document2::manager::DocumentManager;

use crate::document::util::default_collab_builder;

use super::util::FakeUser;

#[test]
fn restore_document() {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user), default_collab_builder());

  // create a document
  let doc_id: String = nanoid!(10);
  let data = default_document_data();
  let document_a = manager
    .create_document(doc_id.clone(), Some(data.clone()))
    .unwrap();
  let data_a = document_a.lock().get_document().unwrap();
  assert_eq!(data_a, data);

  // open a document
  let data_b = manager
    .open_document(doc_id.clone())
    .unwrap()
    .lock()
    .get_document()
    .unwrap();
  // close a document
  _ = manager.close_document(&doc_id);
  assert_eq!(data_b, data);

  // restore
  _ = manager.create_document(doc_id.clone(), Some(data.clone()));
  // open a document
  let data_b = manager
    .open_document(doc_id.clone())
    .unwrap()
    .lock()
    .get_document()
    .unwrap();
  // close a document
  _ = manager.close_document(&doc_id);

  assert_eq!(data_b, data);
}

#[test]
fn document_apply_insert_action() {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user), default_collab_builder());

  let doc_id: String = nanoid!(10);
  let data = default_document_data();

  // create a document
  _ = manager.create_document(doc_id.clone(), Some(data.clone()));

  // open a document
  let document = manager.open_document(doc_id.clone()).unwrap();
  let page_block = document.lock().get_block(&data.page_id).unwrap();

  // insert a text block
  let text_block = Block {
    id: nanoid!(10),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: page_block.id,
    children: nanoid!(10),
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
  let data_a = document.lock().get_document().unwrap();
  // close the original document
  _ = manager.close_document(&doc_id);

  // re-open the document
  let data_b = manager
    .open_document(doc_id.clone())
    .unwrap()
    .lock()
    .get_document()
    .unwrap();
  // close a document
  _ = manager.close_document(&doc_id);

  assert_eq!(data_b, data_a);
}

#[test]
fn document_apply_update_page_action() {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user), default_collab_builder());

  let doc_id: String = nanoid!(10);
  let data = default_document_data();

  // create a document
  _ = manager.create_document(doc_id.clone(), Some(data.clone()));

  // open a document
  let document = manager.open_document(doc_id.clone()).unwrap();
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
  _ = manager.close_document(&doc_id);

  // re-open the document
  let document = manager.open_document(doc_id).unwrap();
  let page_block_new = document.lock().get_block(&data.page_id).unwrap();
  assert_eq!(page_block_old, page_block_new);
  assert!(page_block_new.data.contains_key("delta"));
}

#[test]
fn document_apply_update_action() {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user), default_collab_builder());

  let doc_id: String = nanoid!(10);
  let data = default_document_data();

  // create a document
  _ = manager.create_document(doc_id.clone(), Some(data.clone()));

  // open a document
  let document = manager.open_document(doc_id.clone()).unwrap();
  let page_block = document.lock().get_block(&data.page_id).unwrap();

  // insert a text block
  let text_block_id = nanoid!(10);
  let text_block = Block {
    id: text_block_id.clone(),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: page_block.id,
    children: nanoid!(10),
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
  _ = manager.close_document(&doc_id);

  // re-open the document
  let document = manager.open_document(doc_id.clone()).unwrap();
  let block = document.lock().get_block(&text_block_id).unwrap();
  assert_eq!(block.data, updated_text_block_data);
  // close a document
  _ = manager.close_document(&doc_id);
}
