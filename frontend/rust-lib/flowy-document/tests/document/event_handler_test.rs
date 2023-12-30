use flowy_document::{
  entities::{ConvertDataPayloadPB, ConvertType},
  event_handler::convert_data_to_document_internal,
};

#[test]
fn convert_json_to_document() {
  let json_str = r#"
    {
      "type": "page",
      "children": [
        {
          "type": "paragraph1"
        }
      ]
    }"#;
  let payload = ConvertDataPayloadPB {
    convert_type: ConvertType::Json,
    data: json_str.as_bytes().to_vec(),
  };
  let document_data = convert_data_to_document_internal(payload).unwrap();

  let page_id = document_data.page_id;
  let blocks = document_data.blocks;
  let children_map = document_data.meta.children_map;
  let page_block = blocks.get(&page_id).unwrap();
  let page_children = children_map.get(&page_block.children_id).unwrap();
  assert_eq!(page_children.children.len(), 1);
  let paragraph1 = blocks.get(page_children.children.first().unwrap()).unwrap();
  assert_eq!(paragraph1.ty, "paragraph1");
  assert_eq!(paragraph1.parent_id, page_block.id);
}
