use std::collections::HashMap;
use std::sync::Arc;

use collab_document::blocks::{Block, BlockAction, BlockActionPayload, BlockActionType};

use flowy_document2::document_block_keys::PARAGRAPH_BLOCK_TYPE;
use flowy_document2::document_data::default_document_data;
use flowy_document2::manager::DocumentManager;

use crate::document::util::{default_collab_builder, gen_document_id, gen_id, FakeUser};

#[tokio::test]
async fn undo_redo_test() {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user), default_collab_builder());

  let doc_id: String = gen_document_id();
  let data = default_document_data();

  // create a document
  _ = manager.create_document(&doc_id, Some(data.clone()));

  // open a document
  let document = manager.get_or_open_document(&doc_id).unwrap();
  let document = document.lock();
  let page_block = document.get_block(&data.page_id).unwrap();
  let page_id = page_block.id;
  let text_block_id = gen_id();

  // insert a text block
  let text_block = Block {
    id: text_block_id.clone(),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: page_id.clone(),
    children: gen_id(),
    external_id: None,
    external_type: None,
    data: HashMap::new(),
  };
  let insert_text_action = BlockAction {
    action: BlockActionType::Insert,
    payload: BlockActionPayload {
      block: text_block,
      parent_id: Some(page_id),
      prev_id: None,
    },
  };
  document.apply_action(vec![insert_text_action]);

  let can_undo = document.can_undo();
  assert!(can_undo);
  // undo the insert
  let undo = document.undo();
  assert!(undo);
  assert_eq!(document.get_block(&text_block_id), None);

  let can_redo = document.can_redo();
  assert!(can_redo);
  // redo the insert
  let redo = document.redo();
  assert!(redo);
}
