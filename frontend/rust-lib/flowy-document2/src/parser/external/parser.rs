use crate::parser::external::utils::{flatten_element_to_block, parse_plaintext_to_nested_block};
use crate::parser::parser_entities::{InputType, NestedBlock};
use scraper::Html;

#[derive(Debug, Clone, Default)]
pub struct ExternalDataToDocumentDataParser {
  external_data: String,
  input_type: InputType,
}

impl ExternalDataToDocumentDataParser {
  pub fn new(data: String, input_type: InputType) -> Self {
    Self {
      external_data: data,
      input_type,
    }
  }
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
