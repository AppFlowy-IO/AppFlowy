use std::{collections::HashMap, vec};

use collab_document::blocks::{Block, BlockAction, BlockActionPayload, BlockActionType};
use collab_document::document_data::PARAGRAPH_BLOCK_TYPE;

use crate::document::util;
use crate::document::util::gen_id;

#[tokio::test]
async fn document_apply_insert_block_with_empty_parent_id() {
  let (_, document, page_id) = util::create_and_open_empty_document().await;

  // create a text block with no parent
  let text_block_id = gen_id();
  let text_block = Block {
    id: text_block_id.clone(),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: "".to_string(),
    children: gen_id(),
    external_id: None,
    external_type: None,
    data: HashMap::new(),
  };
  let insert_text_action = BlockAction {
    action: BlockActionType::Insert,
    payload: BlockActionPayload {
      block: Some(text_block),
      parent_id: Some(page_id.clone()),
      prev_id: None,
      delta: None,
      text_id: None,
    },
  };
  document
    .lock()
    .apply_action(vec![insert_text_action])
    .unwrap();

  // read the text block and it's parent id should be the page id
  let block = document.lock().get_block(&text_block_id).unwrap();
  assert_eq!(block.parent, page_id);
}
