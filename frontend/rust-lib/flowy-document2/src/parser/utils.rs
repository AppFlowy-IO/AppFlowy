use crate::parser::constant::DELTA;
use crate::parser::parser_entities::{
  ConvertBlockToHtmlParams, InsertDelta, NestedBlock, Selection,
};
use collab_document::blocks::{Block, DocumentData};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;

pub struct ConvertBlockToJsonParams {
  pub(crate) blocks: HashMap<String, Arc<Block>>,
  pub(crate) relation_map: HashMap<String, Arc<Vec<String>>>,
  pub(crate) delta_map: HashMap<String, Vec<InsertDelta>>,
}
pub fn block_to_nested_json(
  block_id: &str,
  convert_params: &ConvertBlockToJsonParams,
) -> Option<NestedBlock> {
  let blocks = &convert_params.blocks;
  let relation_map = &convert_params.relation_map;
  let delta_map = &convert_params.delta_map;
  // Attempt to retrieve the block using the block_id
  let block = blocks.get(block_id)?;

  // Retrieve the children for this block from the relation map
  let children = relation_map.get(&block.id)?;

  // Recursively convert children blocks to JSON
  let children: Vec<_> = children
    .iter()
    .filter_map(|child_id| block_to_nested_json(child_id, convert_params))
    .collect();

  // Clone block data
  let mut data = block.data.clone();

  // Insert delta into data if available
  if let Some(delta) = delta_map.get(&block.id) {
    if let Ok(delta_value) = serde_json::to_value(delta) {
      data.insert(DELTA.to_string(), delta_value);
    }
  }

  // Create and return the NestedBlock
  Some(NestedBlock {
    id: block.id.to_string(),
    ty: block.ty.to_string(),
    children,
    data,
  })
}

pub fn get_flat_block_ids(block_id: &str, data: &DocumentData) -> Vec<String> {
  let blocks = &data.blocks;
  let children_map = &data.meta.children_map;

  if let Some(block) = blocks.get(block_id) {
    let mut result = vec![block.id.clone()];

    if let Some(child_ids) = children_map.get(&block.children) {
      for child_id in child_ids {
        let child_blocks = get_flat_block_ids(child_id, data);
        result.extend(child_blocks);
      }

      return result;
    }
  }

  vec![]
}

pub fn get_delta_for_block(block_id: &str, data: &DocumentData) -> Option<Vec<InsertDelta>> {
  let text_map = data.meta.text_map.as_ref()?; // Retrieve the text_map reference

  data.blocks.get(block_id).and_then(|block| {
    let text_id = block.external_id.as_ref()?;
    let delta_str = text_map.get(text_id)?;
    serde_json::from_str::<Vec<InsertDelta>>(delta_str).ok()
  })
}

pub fn get_delta_for_selection(
  selection: &Selection,
  data: &DocumentData,
) -> Option<Vec<InsertDelta>> {
  let delta = get_delta_for_block(&selection.block_id, data)?;
  let start = selection.index as usize;
  let end = (selection.index + selection.length) as usize;
  Some(slice_delta(&delta, start, end))
}

pub fn slice_delta(delta: &Vec<InsertDelta>, start: usize, end: usize) -> Vec<InsertDelta> {
  let mut result = vec![];
  let mut index = 0;
  for d in delta {
    let content = &d.insert;
    let text_len = content.len();
    // skip if index is not reached
    if index + text_len <= start {
      index += text_len;
      continue;
    }
    // break if index is over end
    if index >= end {
      break;
    }
    // slice content, and push to result
    let start_offset = std::cmp::max(0, start as isize - index as isize) as usize;
    let end_offset = std::cmp::min(end - index, text_len);
    let content = content[start_offset..end_offset].to_string();
    result.push(InsertDelta {
      insert: content,
      attributes: d.attributes.clone(),
    });

    index += text_len;
  }
  result
}
pub fn delta_to_text(delta: &Vec<InsertDelta>) -> String {
  let mut result = String::new();
  for d in delta {
    result.push_str(d.to_text().as_str());
  }
  result
}

pub fn delta_to_html(delta: &Vec<InsertDelta>) -> String {
  let mut result = String::new();
  for d in delta {
    result.push_str(d.to_html().as_str());
  }
  result
}

pub fn convert_nested_block_children_to_html(block: Arc<NestedBlock>) -> String {
  let children = &block.children;
  let mut html = String::new();
  let num_children = children.len();

  for (i, child) in children.iter().enumerate() {
    let prev_block_ty = if i > 0 {
      Some(children[i - 1].ty.to_string())
    } else {
      None
    };

    let next_block_ty = if i + 1 < num_children {
      Some(children[i + 1].ty.to_string())
    } else {
      None
    };

    let child_html = child.convert_to_html(ConvertBlockToHtmlParams {
      prev_block_ty,
      next_block_ty,
    });

    html.push_str(&child_html);
  }
  html
}

pub fn convert_insert_delta_from_json(delta_value: &Value) -> Option<Vec<InsertDelta>> {
  serde_json::from_value::<Vec<InsertDelta>>(delta_value.to_owned()).ok()
}
