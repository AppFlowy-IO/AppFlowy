use std::{collections::HashMap, vec};

use crate::document::util;
use collab_document::blocks::{Block, BlockAction, BlockActionPayload, BlockActionType};
use flowy_document2::document_block_keys::PARAGRAPH_BLOCK_TYPE;
use nanoid::nanoid;

#[test]
fn document_apply_insert_block_with_empty_parent_id() {
  let (_, document, page_id) = util::create_and_open_empty_document();

  // create a text block with no parent
  let text_block_id = nanoid!(10);
  let text_block = Block {
    id: text_block_id.clone(),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: "".to_string(),
    children: nanoid!(10),
    external_id: None,
    external_type: None,
    data: HashMap::new(),
  };
  let insert_text_action = BlockAction {
    action: BlockActionType::Insert,
    payload: BlockActionPayload {
      block: text_block,
      parent_id: Some(page_id.clone()),
      prev_id: None,
    },
  };
  document.lock().apply_action(vec![insert_text_action]);

  // read the text block and it's parent id should be the page id
  let block = document.lock().get_block(&text_block_id).unwrap();
  assert_eq!(block.parent, page_id);
}
