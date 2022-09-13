use super::script::{NodeScript::*, *};
use lib_ot::core::AttributeBuilder;
use lib_ot::{
    core::{NodeData, Path},
    text_delta::TextDeltaBuilder,
};

#[test]
fn editor_deserialize_node_test() {
    let mut test = NodeTest::new();
    let node: NodeData = serde_json::from_str(EXAMPLE_JSON).unwrap();
    let path: Path = 0.into();

    let expected_delta = TextDeltaBuilder::new()
        .insert("👋 ")
        .insert_with_attributes(
            "Welcome to ",
            AttributeBuilder::new().insert("href", "appflowy.io").build(),
        )
        .insert_with_attributes(
            "AppFlowy Editor",
            AttributeBuilder::new().insert("italic", true).build(),
        )
        .build();

    test.run_scripts(vec![
        InsertNode {
            path,
            node: node.clone(),
        },
        AssertNumberOfNodesAtPath { path: None, len: 1 },
        AssertNumberOfNodesAtPath {
            path: Some(0.into()),
            len: 14,
        },
        AssertNumberOfNodesAtPath {
            path: Some(0.into()),
            len: 14,
        },
        AssertNodeDelta {
            path: vec![0, 1].into(),
            expected: expected_delta,
        },
        AssertNode {
            path: vec![0, 0].into(),
            expected: Some(node.children[0].clone()),
        },
        AssertNode {
            path: vec![0, 3].into(),
            expected: Some(node.children[3].clone()),
        },
    ]);
}

#[allow(dead_code)]
const EXAMPLE_JSON: &str = r#"
{
  "type": "editor",
  "children": [
    {
      "type": "image",
      "attributes": {
        "image_src": "https://s1.ax1x.com/2022/08/26/v2sSbR.jpg",
        "align": "center"
      }
    },
    {
      "type": "text",
      "attributes": {
        "subtype": "heading",
        "heading": "h1"
      },
      "body": {
        "delta": [
          {
            "insert": "👋 "
          },
          {
            "insert": "Welcome to ",
            "attributes": {
              "href": "appflowy.io"
            }
          },
          {
            "insert": "AppFlowy Editor",
            "attributes": {
              "italic": true
            }
          }
        ]
      }
    },
    { "type": "text", "delta": [] },
    {
      "type": "text",
      "body": {
        "delta": [
            { "insert": "AppFlowy Editor is a " },
            { "insert": "highly customizable", "attributes": { "bold": true } },
            { "insert": " " },
            { "insert": "rich-text editor", "attributes": { "italic": true } },
            { "insert": " for " },
            { "insert": "Flutter", "attributes": { "underline": true } }
        ]
      }
    },
    {
      "type": "text",
      "attributes": { "checkbox": true, "subtype": "checkbox" },
      "body": {
        "delta": [{ "insert": "Customizable" }]
      }
    },
    {
      "type": "text",
      "attributes": { "checkbox": true, "subtype": "checkbox" },
      "delta": [{ "insert": "Test-covered" }]
    },
    {
      "type": "text",
      "attributes": { "checkbox": false, "subtype": "checkbox" },
      "delta": [{ "insert": "more to come!" }]
    },
    { "type": "text", "delta": [] },
    {
      "type": "text",
      "attributes": { "subtype": "quote" },
      "delta": [{ "insert": "Here is an exmaple you can give it a try" }]
    },
    { "type": "text", "delta": [] },
    {
      "type": "text",
      "delta": [
        { "insert": "You can also use " },
        {
          "insert": "AppFlowy Editor",
          "attributes": {
            "italic": true,
            "bold": true,
            "backgroundColor": "0x6000BCF0"
          }
        },
        { "insert": " as a component to build your own app." }
      ]
    },
    { "type": "text", "delta": [] },
    {
      "type": "text",
      "attributes": { "subtype": "bulleted-list" },
      "delta": [{ "insert": "Use / to insert blocks" }]
    },
    {
      "type": "text",
      "attributes": { "subtype": "bulleted-list" },
      "delta": [
        {
          "insert": "Select text to trigger to the toolbar to format your notes."
        }
      ]
    }
  ]
}
"#;
