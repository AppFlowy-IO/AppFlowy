use crate::parser::external::utils::{flatten_element_to_block, parse_plaintext_to_nested_block};
use crate::parser::parser_entities::{InputType, NestedBlock};
use scraper::Html;

/// External data to nested json parser.
#[derive(Debug, Clone, Default)]
pub struct ExternalDataToNestedJSONParser {
  /// External data. for example: html string, plain text string.
  external_data: String,
  /// External data type. for example: [InputType]::Html, [InputType]::PlainText.
  input_type: InputType,
}

impl ExternalDataToNestedJSONParser {
  pub fn new(data: String, input_type: InputType) -> Self {
    Self {
      external_data: data,
      input_type,
    }
  }

  /// Format to nested block.
  ///
  /// Example:
  /// - input html: <p><strong>Hello</strong></p><p> World!</p>
  /// - output json:
  /// ```json
  /// { "type": "page", "data": {}, "children": [{ "type": "paragraph", "children": [], "data": { "delta": [{ "insert": "Hello", attributes: { "bold": true } }] } }, { "type": "paragraph", "children": [], "data": { "delta": [{ "insert": " World!", attributes: null }] } }] }
  /// ```
  pub fn to_nested_block(&self) -> Option<NestedBlock> {
    match self.input_type {
      InputType::Html => {
        let fragment = Html::parse_fragment(&self.external_data);
        let root_element = fragment.root_element();
        flatten_element_to_block(root_element)
      },
      InputType::PlainText => parse_plaintext_to_nested_block(&self.external_data),
    }
  }
}
