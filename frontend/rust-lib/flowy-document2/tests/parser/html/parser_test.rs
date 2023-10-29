use flowy_document2::parser::external::parser::ExternalDataToDocumentDataParser;
use flowy_document2::parser::parser_entities::{InputType, NestedBlock};

macro_rules! generate_test_cases {
    ($($ty:ident),*) => {
        [
            $(
                (
                    include_str!(concat!("../../assets/json/", stringify!($ty), ".json")),
                    include_str!(concat!("../../assets/html/", stringify!($ty), ".html")),
                )
            ),*
        ]
    };
}
#[tokio::test]
async fn html_to_document_test() {
  let test_cases = generate_test_cases!(notion, google_docs);

  for (json, html) in test_cases.iter() {
    let parser = ExternalDataToDocumentDataParser::new(html.to_string(), InputType::Html);
    let block = parser.to_nested_block();
    assert!(block.is_some());
    let block = block.unwrap();
    let expect_block = serde_json::from_str::<NestedBlock>(json).unwrap();
    assert_eq!(block, expect_block);
  }
}

#[tokio::test]
async fn plain_text_to_document_test() {
  let plain_text = include_str!("../../assets/text/plain_text.txt");
  let parser = ExternalDataToDocumentDataParser::new(plain_text.to_string(), InputType::PlainText);
  let block = parser.to_nested_block();
  assert!(block.is_some());
  let expect_json = include_str!("../../assets/json/plain_text.json");
  let expect_block = serde_json::from_str::<NestedBlock>(expect_json).unwrap();
  assert_eq!(block.unwrap(), expect_block);
}
