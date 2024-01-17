use collab_document::blocks::json_str_to_hashmap;
use flowy_document::parser::json::parser::JsonToDocumentParser;
use serde_json::json;

#[test]
fn test_parser_children_in_order() {
  let json = json!({
    "type": "page",
    "children": [
      {
        "type": "paragraph1",
      },
      {
        "type": "paragraph2",
      },
      {
        "type": "paragraph3",
      },
      {
        "type": "paragraph4",
      }
    ]
  });

  let document = JsonToDocumentParser::json_str_to_document(json.to_string().as_str()).unwrap();

  // root + 4 paragraphs
  assert_eq!(document.blocks.len(), 5);

  // root + 4 paragraphs
  assert_eq!(document.meta.children_map.len(), 5);

  let (page_id, page_block) = document
    .blocks
    .iter()
    .find(|(_, block)| block.ty == "page")
    .unwrap();

  // the children should be in order
  let page_children = document
    .meta
    .children_map
    .get(page_block.children_id.as_str())
    .unwrap();
  assert_eq!(page_children.children.len(), 4);
  for (i, child_id) in page_children.children.iter().enumerate() {
    let child = document.blocks.get(child_id).unwrap();
    assert_eq!(child.ty, format!("paragraph{}", i + 1));
    assert_eq!(child.parent_id, page_id.to_owned());
  }
}

#[test]
fn test_parser_nested_children() {
  let json = json!({
    "type": "page",
    "children": [
      {
        "type": "paragraph",
        "children": [
          {
            "type": "paragraph",
            "children": [
              {
                "type": "paragraph",
                "children": [
                  {
                    "type": "paragraph"
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  });

  let document = JsonToDocumentParser::json_str_to_document(json.to_string().as_str()).unwrap();

  // root + 4 paragraphs
  assert_eq!(document.blocks.len(), 5);

  // root + 4 paragraphs
  assert_eq!(document.meta.children_map.len(), 5);

  let (page_id, page_block) = document
    .blocks
    .iter()
    .find(|(_, block)| block.ty == "page")
    .unwrap();

  // first child of root is a paragraph
  let page_children = document
    .meta
    .children_map
    .get(page_block.children_id.as_str())
    .unwrap();
  assert_eq!(page_children.children.len(), 1);
  let page_first_child_id = page_children.children.first().unwrap();
  let page_first_child = document.blocks.get(page_first_child_id).unwrap();
  assert_eq!(page_first_child.ty, "paragraph");
  assert_eq!(page_first_child.parent_id, page_id.to_owned());
}

#[tokio::test]
async fn parse_readme_test() {
  let json = include_str!("../../../../flowy-core/assets/read_me.json");
  let document = JsonToDocumentParser::json_str_to_document(json).unwrap();

  document.blocks.iter().for_each(|(_, block)| {
    let data = json_str_to_hashmap(&block.data).ok();
    assert!(data.is_some());
    if let Some(data) = data {
      assert!(data.get("delta").is_none());
    }

    if let Some(external_id) = &block.external_id {
      let text = document.meta.text_map.get(external_id);
      assert!(text.is_some());
    }
  });
}
