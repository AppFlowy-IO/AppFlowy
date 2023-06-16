use flowy_document2::entities::*;
use flowy_test::document_event::OpenDocumentData;
use nanoid::nanoid;
use std::collections::HashMap;

pub fn gen_id() -> String {
  nanoid!(10)
}

pub struct ParseDocumentData {
  pub doc_id: String,
  pub page_id: String,
  pub blocks: HashMap<String, BlockPB>,
  pub children_map: HashMap<String, ChildrenPB>,
  pub first_block_id: String,
}
pub fn parse_document_data(document: OpenDocumentData) -> ParseDocumentData {
  let doc_id = document.id.clone();
  let data = document.data;
  let page_id = data.page_id;
  let blocks = data.blocks;
  let children_map = data.meta.children_map;
  let page_block = blocks.get(&page_id).unwrap();
  let children_id = page_block.children_id.clone();
  let children = children_map.get(&children_id).unwrap();
  let block_id = children.children.get(0).unwrap().to_string();
  ParseDocumentData {
    doc_id,
    page_id,
    blocks,
    children_map,
    first_block_id: block_id,
  }
}

pub fn gen_insert_block_action(document: OpenDocumentData) -> BlockActionPB {
  let parse_data = parse_document_data(document);
  let first_block_id = parse_data.first_block_id;
  let block = parse_data.blocks.get(&first_block_id).unwrap();
  let page_id = parse_data.page_id;
  let data = block.data.clone();
  let new_block_id = gen_id();
  let new_block = BlockPB {
    id: new_block_id.clone(),
    ty: block.ty.clone(),
    data,
    parent_id: page_id.clone(),
    children_id: gen_id(),
  };
  BlockActionPB {
    action: BlockActionTypePB::Insert,
    payload: BlockActionPayloadPB {
      block: new_block,
      prev_id: Some(first_block_id),
      parent_id: Some(page_id),
    },
  }
}
