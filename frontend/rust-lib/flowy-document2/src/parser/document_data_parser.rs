use crate::parser::parser_entities::{ConvertBlockToHtmlParams, NestedBlock, Range};
use crate::parser::utils::{
  block_to_nested_json, get_delta_for_block, get_delta_for_selection, get_flat_block_ids,
  ConvertBlockToJsonParams,
};
use collab_document::blocks::DocumentData;
use std::collections::HashMap;
use std::sync::Arc;

/// DocumentDataParser is a struct for parsing a document's data and converting it to JSON, HTML, or text.
pub struct DocumentDataParser {
  /// The document data to parse.
  pub document_data: Arc<DocumentData>,
  /// The range of the document data to parse. If the range is None, the entire document data will be parsed.
  pub range: Option<Range>,
}

impl DocumentDataParser {
  pub fn new(document_data: Arc<DocumentData>, range: Option<Range>) -> Self {
    Self {
      document_data,
      range,
    }
  }

  /// Converts the JSON to an HTML representation.
  pub fn to_html_with_json(&self, json: &Option<NestedBlock>) -> String {
    let mut html = String::new();
    html.push_str("<meta charset=\"UTF-8\">");
    if let Some(json) = json {
      let params = ConvertBlockToHtmlParams {
        prev_block_ty: None,
        next_block_ty: None,
      };
      html.push_str(json.convert_to_html(params).as_str());
    }
    html
  }

  /// Converts the JSON to plain text.
  pub fn to_text_with_json(&self, json: &Option<NestedBlock>) -> String {
    if let Some(json) = json {
      json.convert_to_text()
    } else {
      String::new()
    }
  }

  /// Converts the document data to HTML.
  pub fn to_html(&self) -> String {
    let json = self.to_json();
    self.to_html_with_json(&json)
  }

  /// Converts the document data to plain text.
  pub fn to_text(&self) -> String {
    let json = self.to_json();
    self.to_text_with_json(&json)
  }

  /// Converts the document data to a nested JSON structure, considering the optional range.
  pub fn to_json(&self) -> Option<NestedBlock> {
    let root_id = &self.document_data.page_id;
    // flatten the block id list.
    let block_id_list = get_flat_block_ids(root_id, &self.document_data);

    // collect the block ids in the range.
    let mut in_range_block_ids = self.collect_in_range_block_ids(&block_id_list);
    // insert the root block id if it is not in the in-range block ids.
    if !in_range_block_ids.contains(root_id) {
      in_range_block_ids.push(root_id.to_string());
    }

    // build the parameters for converting the block to JSON with the in-range block ids.
    let convert_params = self.build_convert_json_params(&in_range_block_ids);
    // convert the root block to JSON.
    let mut root = block_to_nested_json(root_id, &convert_params)?;

    // If the start block's parent is outside the in-range selection, we need to insert the start block.
    if self.should_insert_start_block() {
      self.insert_start_block_json(&mut root, &convert_params);
    }

    Some(root)
  }

  /// Collects the block ids in the range.
  fn collect_in_range_block_ids(&self, block_id_list: &Vec<String>) -> Vec<String> {
    if let Some(range) = &self.range {
      // Find the positions of start and end block IDs in the list
      let mut start_index = block_id_list
        .iter()
        .position(|id| id == &range.start.block_id)
        .unwrap_or(0);
      let mut end_index = block_id_list
        .iter()
        .position(|id| id == &range.end.block_id)
        .unwrap_or(0);

      if start_index > end_index {
        // Swap start and end if they are in reverse order
        std::mem::swap(&mut start_index, &mut end_index);
      }

      // Slice the block IDs based on the positions of start and end
      block_id_list[start_index..=end_index].to_vec()
    } else {
      // If no range is specified, return the entire list
      block_id_list.to_owned()
    }
  }

  /// Builds the parameters for converting the block to JSON.
  /// ConvertBlockToJsonParams format:
  /// {
  ///   blocks: HashMap<String, Arc<Block>>, // in-range blocks
  ///   relation_map: HashMap<String, Arc<Vec<String>>>, // in-range blocks' children
  ///   delta_map: HashMap<String, String>, // in-range blocks' delta
  /// }
  fn build_convert_json_params(&self, block_id_list: &[String]) -> ConvertBlockToJsonParams {
    let mut delta_map = HashMap::new();
    let mut in_range_blocks = HashMap::new();
    let mut relation_map = HashMap::new();

    for block_id in block_id_list {
      if let Some(block) = self.document_data.blocks.get(block_id) {
        // Insert the block into the in-range block map.
        in_range_blocks.insert(block_id.to_string(), Arc::new(block.to_owned()));

        // If the block has children, insert the children into the relation map.
        if let Some(children) = self.document_data.meta.children_map.get(&block.children) {
          relation_map.insert(block_id.to_string(), Arc::new(children.to_owned()));
        }

        let delta = match &self.range {
          Some(range) if block_id == &range.start.block_id => {
            get_delta_for_selection(&range.start, &self.document_data)
          },
          Some(range) if block_id == &range.end.block_id => {
            get_delta_for_selection(&range.end, &self.document_data)
          },
          _ => get_delta_for_block(block_id, &self.document_data),
        };

        // If the delta exists, insert it into the delta map.
        if let Some(delta) = delta {
          delta_map.insert(block_id.to_string(), delta);
        }
      }
    }

    ConvertBlockToJsonParams {
      blocks: in_range_blocks,
      relation_map,
      delta_map,
    }
  }

  // Checks if the start block should be inserted whether the start block's parent is outside the in-range selection.
  fn should_insert_start_block(&self) -> bool {
    if let Some(range) = &self.range {
      if let Some(start_block) = self.document_data.blocks.get(&range.start.block_id) {
        return start_block.parent != self.document_data.page_id;
      }
    }
    false
  }

  // Inserts the start block JSON to the root JSON.
  fn insert_start_block_json(
    &self,
    root: &mut NestedBlock,
    convert_params: &ConvertBlockToJsonParams,
  ) {
    let start = &self.range.as_ref().unwrap().start;
    if let Some(start_block_json) = block_to_nested_json(&start.block_id, convert_params) {
      root.children.insert(0, start_block_json);
    }
  }
}
