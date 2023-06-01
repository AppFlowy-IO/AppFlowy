use std::{collections::HashMap, vec};

use flowy_error::FlowyResult;
use indexmap::IndexMap;
use nanoid::nanoid;

use crate::entities::{BlockPB, ChildrenPB, DocumentDataPB, MetaPB};

use super::block::Block;

pub struct JsonToDocumentParser;

impl JsonToDocumentParser {
  pub fn json_str_to_document(json_str: &str) -> FlowyResult<DocumentDataPB> {
    let root = serde_json::from_str::<Block>(json_str)?;

    let page_id = nanoid!(10);

    // generate the blocks
    // the root's parent id is itself
    let blocks = Self::generate_blocks(&root, Some(page_id.clone()), "".to_owned());

    // generate the children map
    let children_map = Self::generate_children_map(&blocks);

    return Ok(DocumentDataPB {
      page_id,
      blocks: blocks.into_iter().collect(),
      meta: MetaPB { children_map },
    });
  }

  fn generate_blocks(
    block: &Block,
    id: Option<String>,
    parent_id: String,
  ) -> IndexMap<String, BlockPB> {
    let block_pb = Self::block_to_block_pb(block, id, parent_id);
    let mut blocks = IndexMap::new();
    for child in block.children.iter() {
      let child_blocks = Self::generate_blocks(child, None, block_pb.id.clone());
      blocks.extend(child_blocks);
    }
    blocks.insert(block_pb.id.clone(), block_pb);
    return blocks;
  }

  fn generate_children_map(blocks: &IndexMap<String, BlockPB>) -> HashMap<String, ChildrenPB> {
    let mut children_map = HashMap::new();
    for (id, block) in blocks.iter() {
      // add itself to it's parent's children
      if block.parent_id.is_empty() {
        continue;
      }
      let children = children_map
        .entry(block.parent_id.clone())
        .or_insert(ChildrenPB { children: vec![] });
      children.children.push(id.clone());
      // create a children map entry for itself
      children_map.insert(id.clone(), ChildrenPB { children: vec![] });
    }
    return children_map;
  }

  fn block_to_block_pb(block: &Block, id: Option<String>, parent_id: String) -> BlockPB {
    let id = id.unwrap_or(nanoid!(10));
    let block_pb = BlockPB {
      id: id.clone(),
      ty: block.ty.clone(),
      data: serde_json::to_string(&block.data).unwrap(),
      parent_id: parent_id.clone(),
      children_id: id.clone(),
    };
    return block_pb;
  }
}
