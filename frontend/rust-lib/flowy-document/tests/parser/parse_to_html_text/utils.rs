use flowy_document::parser::document_data_parser::DocumentDataParser;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use std::sync::Arc;

pub fn assert_document_html_eq(source: &str, expect: &str) {
  let document_data = JsonToDocumentParser::json_str_to_document(source)
    .unwrap()
    .into();
  let parser = DocumentDataParser::new(Arc::new(document_data), None);
  let html = parser.to_html();
  assert_eq!(expect, html);
}

pub fn assert_document_text_eq(source: &str, expect: &str) {
  let document_data = JsonToDocumentParser::json_str_to_document(source)
    .unwrap()
    .into();
  let parser = DocumentDataParser::new(Arc::new(document_data), None);
  let text = parser.to_text();
  assert_eq!(expect, text);
}
