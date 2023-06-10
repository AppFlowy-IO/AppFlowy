use crate::document::util::{default_collab_builder, FakeUser};
use collab_document::blocks::{Block, BlockAction, BlockActionPayload, BlockActionType};
use flowy_document2::document_block_keys::PARAGRAPH_BLOCK_TYPE;
use flowy_document2::document_data::default_document_data;
use flowy_document2::manager::DocumentManager;
use nanoid::nanoid;
use std::collections::HashMap;
use std::sync::Arc;

#[tokio::test]
async fn undo_redo() {
  let user = FakeUser::new();
  let manager = DocumentManager::new(Arc::new(user), default_collab_builder());

  let doc_id: String = nanoid!(10);
  let data = default_document_data();

  // create a document
  _ = manager.create_document(doc_id.clone(), Some(data.clone()));

  // open a document
  let document = manager.open_document(doc_id.clone()).unwrap();
  let page_block = document.lock().get_block(&data.page_id).unwrap();
  let page_id = page_block.id;
  let text_block_id = nanoid!(10);

  // insert a text block
  let text_block = Block {
    id: text_block_id.clone(),
    ty: PARAGRAPH_BLOCK_TYPE.to_string(),
    parent: page_id.clone(),
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

  assert_eq!(
    document.lock().get_block(&text_block_id).unwrap().parent,
    page_id
  );

  let can_undo = manager.can_undo(&doc_id.clone()).unwrap();
  assert!(can_undo);
  // undo the insert
  let undo = manager.undo(&doc_id.clone()).unwrap();
  assert_eq!(undo, true);
  assert_eq!(document.lock().get_block(&text_block_id), None);

  let can_redo = manager.can_redo(&doc_id.clone()).unwrap();
  assert!(can_redo);
  // redo the insert
  let redo = manager.redo(&doc_id.clone()).unwrap();
  assert_eq!(redo, true);
  assert_eq!(
    document.lock().get_block(&text_block_id).unwrap().parent,
    page_id
  )
}
