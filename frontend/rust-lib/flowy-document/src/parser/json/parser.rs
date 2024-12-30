use std::{collections::HashMap, vec};

use indexmap::IndexMap;
use nanoid::nanoid;

use flowy_error::FlowyResult;

use crate::entities::{BlockPB, ChildrenPB, DocumentDataPB, MetaPB};

use super::block::SerdeBlock;

pub struct JsonToDocumentParser;

const DELTA: &str = "delta";
const TEXT_EXTERNAL_TYPE: &str = "text";
impl JsonToDocumentParser {
  pub fn json_str_to_document(json_str: &str) -> FlowyResult<DocumentDataPB> {
    let root = serde_json::from_str::<SerdeBlock>(json_str)?;

    let page_id = nanoid!(10);

    // generate the blocks
    // the root's parent id is empty
    let (blocks, text_map) = Self::generate_blocks(&root, Some(page_id.clone()), "".to_string());

    // generate the children map
    let children_map = Self::generate_children_map(&blocks);

    // generate the text map
    let text_map = Self::generate_text_map(&text_map);
    Ok(DocumentDataPB {
      page_id,
      blocks: blocks.into_iter().collect(),
      meta: MetaPB {
        children_map,
        text_map,
      },
    })
  }

  fn generate_blocks(
    block: &SerdeBlock,
    id: Option<String>,
    parent_id: String,
  ) -> (IndexMap<String, BlockPB>, IndexMap<String, String>) {
    let (block_pb, delta) = Self::block_to_block_pb(block, id, parent_id);
    let mut blocks = IndexMap::new();
    let mut text_map = IndexMap::new();
    for child in &block.children {
      let (child_blocks, child_blocks_text_map) =
        Self::generate_blocks(child, None, block_pb.id.clone());
      blocks.extend(child_blocks);
      text_map.extend(child_blocks_text_map);
    }
    let external_id = block_pb.external_id.clone();
    blocks.insert(block_pb.id.clone(), block_pb);
    if let Some(delta) = delta {
      if let Some(external_id) = external_id {
        text_map.insert(external_id, delta);
      }
    }
    (blocks, text_map)
  }

  fn generate_text_map(text_map: &IndexMap<String, String>) -> HashMap<String, String> {
    text_map
      .iter()
      .map(|(k, v)| (k.clone(), v.clone()))
      .collect()
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

  fn block_to_block_pb(
    block: &SerdeBlock,
    id: Option<String>,
    parent_id: String,
  ) -> (BlockPB, Option<String>) {
    let id = id.unwrap_or_else(|| nanoid!(10));
    let mut data = block.data.clone();

    let delta = data.remove(DELTA).map(|d| d.to_string());

    let (external_id, external_type) = match delta {
      None => (None, None),
      Some(_) => (Some(nanoid!(10)), Some(TEXT_EXTERNAL_TYPE.to_string())),
    };

    (
      BlockPB {
        id,
        ty: block.ty.clone(),
        data: serde_json::to_string(&data).unwrap(),
        parent_id,
        children_id: nanoid!(10),
        external_id,
        external_type,
      },
      delta,
    )
  }
}
