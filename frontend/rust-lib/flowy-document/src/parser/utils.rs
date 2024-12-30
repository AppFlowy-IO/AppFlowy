use crate::parser::parser_entities::{
  ConvertBlockToHtmlParams, InsertDelta, NestedBlock, Selection,
};
use collab_document::blocks::DocumentData;
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;
use validator::ValidationError;

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

pub fn required_not_empty_str(s: &str) -> Result<(), ValidationError> {
  if s.is_empty() {
    return Err(ValidationError::new("should not be empty string"));
  }
  Ok(())
}

pub fn serialize_color_attribute(
  attrs: &HashMap<String, Value>,
  attr_name: &str,
  css_property: &str,
) -> String {
  if let Some(color) = attrs.get(attr_name) {
    return format!(
      "{}: {};",
      css_property,
      color.to_string().replace("0x", "#").trim_matches('\"')
    );
  }
  "".to_string()
}
