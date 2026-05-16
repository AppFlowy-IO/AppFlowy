use collab_document::blocks::DocumentData;
use flowy_document::parser::document_data_parser::DocumentDataParser;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use flowy_document::parser::parser_entities::{NestedBlock, Range, Selection};
use std::sync::Arc;

#[tokio::test]
async fn document_data_parse_json_test() {
  let initial_json_str = include_str!("../assets/json/initial_document.json");
  let document_data = JsonToDocumentParser::json_str_to_document(initial_json_str)
    .unwrap()
    .into();
  let parser = DocumentDataParser::new(Arc::new(document_data), None);
  let read_me_json = serde_json::from_str::<NestedBlock>(initial_json_str).unwrap();
  let json = parser.to_json().unwrap();
  assert_eq!(read_me_json, json);
}

// range_1 is a range from the 2nd block to the 8th block
#[tokio::test]
async fn document_data_to_json_with_range_1_test() {
  let initial_json_str = include_str!("../assets/json/initial_document.json");
  let document_data: DocumentData = JsonToDocumentParser::json_str_to_document(initial_json_str)
    .unwrap()
    .into();

  let children_map = &document_data.meta.children_map;
  let page_block_id = &document_data.page_id;
  let blocks = &document_data.blocks;
  let page_block = blocks.get(page_block_id).unwrap();
  let children = children_map.get(page_block.children.as_str()).unwrap();

  let range = Range {
    start: Selection {
      block_id: children.get(1).unwrap().to_string(),
      index: 4,
      length: 15,
    },
    end: Selection {
      block_id: children.get(7).unwrap().to_string(),
      index: 0,
      length: 11,
    },
  };
  let parser = DocumentDataParser::new(Arc::new(document_data), Some(range));
  let json = parser.to_json().unwrap();
  let part_1 = include_str!("../assets/json/range_1.json");
  let part_1_json = serde_json::from_str::<NestedBlock>(part_1).unwrap();
  assert_eq!(part_1_json, json);
}

// range_2 is a range from the 4th block's first child to the 18th block's first child
#[tokio::test]
async fn document_data_to_json_with_range_2_test() {
  let initial_json_str = include_str!("../assets/json/initial_document.json");
  let document_data: DocumentData = JsonToDocumentParser::json_str_to_document(initial_json_str)
    .unwrap()
    .into();

  let children_map = &document_data.meta.children_map;
  let page_block_id = &document_data.page_id;
  let blocks = &document_data.blocks;
  let page_block = blocks.get(page_block_id).unwrap();

  let start_block_parent_id = children_map
    .get(page_block.children.as_str())
    .unwrap()
    .get(3)
    .unwrap();
  let start_block_parent = blocks.get(start_block_parent_id).unwrap();
  let start_block_id = children_map
    .get(start_block_parent.children.as_str())
    .unwrap()
    .first()
    .unwrap();

  let start = Selection {
    block_id: start_block_id.to_string(),
    index: 6,
    length: 27,
  };

  let end_block_parent_id = children_map
    .get(page_block.children.as_str())
    .unwrap()
    .get(17)
    .unwrap();
  let end_block_parent = blocks.get(end_block_parent_id).unwrap();
  let end_block_children = children_map
    .get(end_block_parent.children.as_str())
    .unwrap();
  let end_block_id = end_block_children.first().unwrap();
  let end = Selection {
    block_id: end_block_id.to_string(),
    index: 0,
    length: 11,
  };

  let range = Range { start, end };
  let parser = DocumentDataParser::new(Arc::new(document_data), Some(range));
  let json = parser.to_json().unwrap();
  let part_2 = include_str!("../assets/json/range_2.json");
  let part_2_json = serde_json::from_str::<NestedBlock>(part_2).unwrap();
  assert_eq!(part_2_json, json);
}
