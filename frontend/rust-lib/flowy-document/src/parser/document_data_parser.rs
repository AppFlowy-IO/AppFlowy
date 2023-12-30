use crate::parser::constant::DELTA;
use crate::parser::parser_entities::{ConvertBlockToHtmlParams, InsertDelta, NestedBlock, Range};
use crate::parser::utils::{get_delta_for_block, get_delta_for_selection};
use collab_document::blocks::DocumentData;
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
    let mut children = vec![];
    let mut start_found = false;
    let mut end_found = false;

    self
      .block_to_nested_block(root_id, &mut children, &mut start_found, &mut end_found)
      .map(|mut root| {
        root.data.clear();
        root
      })
  }

  fn block_to_nested_block(
    &self,
    block_id: &str,
    children: &mut Vec<NestedBlock>,
    start_found: &mut bool,
    end_found: &mut bool,
  ) -> Option<NestedBlock> {
    let block = self.document_data.blocks.get(block_id)?;
    let delta = self.get_delta(block_id);

    // Prepare the data, including delta if available
    let mut data = block.data.clone();
    if let Some(delta) = delta {
      if let Ok(delta_value) = serde_json::to_value(delta) {
        data.insert(DELTA.to_string(), delta_value);
      }
    }

    // Get the child IDs for the current block
    if let Some(block_children_ids) = self.document_data.meta.children_map.get(&block.children) {
      for child_id in block_children_ids {
        if let Some(range) = &self.range {
          if child_id == &range.start.block_id {
            *start_found = true;
          }

          if child_id == &range.end.block_id {
            *end_found = true;
            // Process the "end" block recursively
            self.process_child_block(child_id, children, start_found, end_found);
            break;
          }
        }

        if self.range.is_some() {
          if !*start_found {
            // Don't insert children before the "start" block is found
            self.block_to_nested_block(child_id, children, start_found, end_found);
            continue;
          }
          if *end_found {
            // Stop inserting children after the "end" block is found
            break;
          }
        }

        // Process child blocks recursively
        self.process_child_block(child_id, children, start_found, end_found);
      }
    }

    Some(NestedBlock {
      ty: block.ty.clone(),
      children: children.to_owned(),
      data,
    })
  }

  fn get_delta(&self, block_id: &str) -> Option<Vec<InsertDelta>> {
    match &self.range {
      Some(range) if block_id == range.start.block_id => {
        get_delta_for_selection(&range.start, &self.document_data)
      },
      Some(range) if block_id == range.end.block_id => {
        get_delta_for_selection(&range.end, &self.document_data)
      },
      _ => get_delta_for_block(block_id, &self.document_data),
    }
  }

  fn process_child_block(
    &self,
    child_id: &str,
    children: &mut Vec<NestedBlock>,
    start_found: &mut bool,
    end_found: &mut bool,
  ) {
    let mut child_children = vec![];
    if let Some(child) =
      self.block_to_nested_block(child_id, &mut child_children, start_found, end_found)
    {
      children.push(child);
    }
  }
}
