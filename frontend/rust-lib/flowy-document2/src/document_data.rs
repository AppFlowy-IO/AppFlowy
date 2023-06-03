use std::{collections::HashMap, vec};

use collab_document::blocks::{Block, DocumentData, DocumentMeta};
use nanoid::nanoid;

use crate::{
  document_block_keys::{PAGE, PARAGRAPH_BLOCK_TYPE},
  entities::{BlockPB, ChildrenPB, DocumentDataPB, MetaPB},
};

impl From<DocumentData> for DocumentDataPB {
  fn from(data: DocumentData) -> Self {
    let blocks = data
      .blocks
      .into_iter()
      .map(|(id, block)| (id, block.into()))
      .collect();

    let children_map = data
      .meta
      .children_map
      .into_iter()
      .map(|(id, children)| (id, children.into()))
      .collect();

    let page_id = data.page_id;

    Self {
      page_id,
      blocks,
      meta: MetaPB { children_map },
    }
  }
}

impl From<DocumentDataPB> for DocumentData {
  fn from(data: DocumentDataPB) -> Self {
    let blocks = data
      .blocks
      .into_iter()
      .map(|(id, block)| (id, block.into()))
      .collect();

    let children_map = data
      .meta
      .children_map
      .into_iter()
      .map(|(id, children)| (id, children.children))
      .collect();

    let page_id = data.page_id;

    DocumentData {
      page_id,
      blocks,
      meta: DocumentMeta { children_map },
    }
  }
}

/// The default document data.
/// The default document data is a document with a page block and a text block.
pub fn default_document_data() -> DocumentData {
  let page_type = PAGE.to_string();
  let text_type = PARAGRAPH_BLOCK_TYPE.to_string();

  let mut blocks: HashMap<String, Block> = HashMap::new();
  let mut meta: HashMap<String, Vec<String>> = HashMap::new();

  // page block
  let page_id = nanoid!(10);
  let children_id = nanoid!(10);
  let root = Block {
    id: page_id.clone(),
    ty: page_type,
    parent: "".to_string(),
    children: children_id.clone(),
    external_id: None,
    external_type: None,
    data: HashMap::new(),
  };
  blocks.insert(page_id.clone(), root);

  // text block
  let text_block_id = nanoid!(10);
  let text_block_children_id = nanoid!(10);
  let text_block = Block {
    id: text_block_id.clone(),
    ty: text_type,
    parent: page_id.clone(),
    children: text_block_children_id.clone(),
    external_id: None,
    external_type: None,
    data: HashMap::new(),
  };
  blocks.insert(text_block_id.clone(), text_block);

  // meta
  meta.insert(children_id, vec![text_block_id]);
  meta.insert(text_block_children_id, vec![]);

  DocumentData {
    page_id,
    blocks,
    meta: DocumentMeta { children_map: meta },
  }
}

impl From<Block> for BlockPB {
  fn from(block: Block) -> Self {
    Self {
      id: block.id,
      ty: block.ty,
      data: serde_json::to_string(&block.data).unwrap_or_default(),
      parent_id: block.parent,
      children_id: block.children,
    }
  }
}

impl From<Vec<String>> for ChildrenPB {
  fn from(children: Vec<String>) -> Self {
    Self { children }
  }
}
