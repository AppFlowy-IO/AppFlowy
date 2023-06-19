use std::{collections::HashMap, vec};

use indexmap::IndexMap;
use nanoid::nanoid;

use flowy_error::FlowyResult;

use crate::entities::{BlockPB, ChildrenPB, DocumentDataPB, MetaPB};

use super::block::Block;

pub struct JsonToDocumentParser;

impl JsonToDocumentParser {
  pub fn json_str_to_document(json_str: &str) -> FlowyResult<DocumentDataPB> {
    let root = serde_json::from_str::<Block>(json_str)?;

    let page_id = nanoid!(10);

    // generate the blocks
    // the root's parent id is empty
    let blocks = Self::generate_blocks(&root, Some(page_id.clone()), "".to_string());

    // generate the children map
    let children_map = Self::generate_children_map(&blocks);

    Ok(DocumentDataPB {
      page_id,
      blocks: blocks.into_iter().collect(),
      meta: MetaPB { children_map },
    })
  }

  fn generate_blocks(
    block: &Block,
    id: Option<String>,
    parent_id: String,
  ) -> IndexMap<String, BlockPB> {
    let block_pb = Self::block_to_block_pb(block, id, parent_id);
    let mut blocks = IndexMap::new();
    for child in &block.children {
      let child_blocks = Self::generate_blocks(child, None, block_pb.id.clone());
      blocks.extend(child_blocks);
    }
    blocks.insert(block_pb.id.clone(), block_pb);
    blocks
  }

  fn generate_children_map(blocks: &IndexMap<String, BlockPB>) -> HashMap<String, ChildrenPB> {
    let mut children_map = HashMap::new();
    for (id, block) in blocks.iter() {
      // add itself to it's parent's children
      if block.parent_id.is_empty() {
        continue;
      }
      let parent_block = blocks.get(&block.parent_id);
      if let Some(parent_block) = parent_block {
        // insert itself to it's parent's children
        let children_pb = children_map
          .entry(parent_block.children_id.clone())
          .or_insert_with(|| ChildrenPB { children: vec![] });
        children_pb.children.push(id.clone());
        // create a children map entry for itself
        children_map
          .entry(block.children_id.clone())
          .or_insert_with(|| ChildrenPB { children: vec![] });
      }
    }
    children_map
  }

  fn block_to_block_pb(block: &Block, id: Option<String>, parent_id: String) -> BlockPB {
    let id = id.unwrap_or_else(|| nanoid!(10));
    BlockPB {
      id,
      ty: block.ty.clone(),
      data: serde_json::to_string(&block.data).unwrap(),
      parent_id,
      children_id: nanoid!(10),
    }
  }
}
