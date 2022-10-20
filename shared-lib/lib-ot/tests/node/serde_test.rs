use lib_ot::core::{
    AttributeBuilder, Changeset, Extension, NodeData, NodeDataBuilder, NodeOperation, NodeTree, Path, Selection,
    Transaction,
};
use lib_ot::text_delta::TextOperationBuilder;

#[test]
fn operation_insert_node_serde_test() {
    let insert = NodeOperation::Insert {
        path: Path(vec![0, 1]),
        nodes: vec![NodeData::new("text".to_owned())],
    };
    let result = serde_json::to_string(&insert).unwrap();
    assert_eq!(result, r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text"}]}"#);
}

#[test]
fn operation_insert_node_with_children_serde_test() {
    let node = NodeDataBuilder::new("text")
        .add_node_data(NodeData::new("sub_text".to_owned()))
        .build();

    let insert = NodeOperation::Insert {
        path: Path(vec![0, 1]),
        nodes: vec![node],
    };
    assert_eq!(
        serde_json::to_string(&insert).unwrap(),
        r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text","children":[{"type":"sub_text"}]}]}"#
    );
}
#[test]
fn operation_update_node_attributes_serde_test() {
    let operation = NodeOperation::Update {
        path: Path(vec![0, 1]),
        changeset: Changeset::Attributes {
            new: AttributeBuilder::new().insert("bold", true).build(),
            old: AttributeBuilder::new().insert("bold", false).build(),
        },
    };

    let result = serde_json::to_string(&operation).unwrap();
    assert_eq!(
        result,
        r#"{"op":"update","path":[0,1],"changeset":{"attributes":{"new":{"bold":true},"old":{"bold":null}}}}"#
    );
}

#[test]
fn operation_update_node_body_serialize_test() {
    let delta = TextOperationBuilder::new().insert("AppFlowy...").build();
    let inverted = delta.invert_str("");
    let changeset = Changeset::Delta { delta, inverted };
    let insert = NodeOperation::Update {
        path: Path(vec![0, 1]),
        changeset,
    };
    let result = serde_json::to_string(&insert).unwrap();
    assert_eq!(
        result,
        r#"{"op":"update","path":[0,1],"changeset":{"delta":{"delta":[{"insert":"AppFlowy..."}],"inverted":[{"delete":11}]}}}"#
    );
}

#[test]
fn operation_update_node_body_deserialize_test() {
    let json_1 = r#"{"op":"update","path":[0,1],"changeset":{"delta":{"delta":[{"insert":"AppFlowy..."}],"inverted":[{"delete":11}]}}}"#;
    let operation: NodeOperation = serde_json::from_str(json_1).unwrap();
    let json_2 = serde_json::to_string(&operation).unwrap();
    assert_eq!(json_1, json_2);
}

#[test]
fn transaction_serialize_test() {
    let insert = NodeOperation::Insert {
        path: Path(vec![0, 1]),
        nodes: vec![NodeData::new("text".to_owned())],
    };
    let mut transaction = Transaction::from_operations(vec![insert]);
    let json = serde_json::to_string(&transaction).unwrap();
    assert_eq!(
        json,
        r#"{"operations":[{"op":"insert","path":[0,1],"nodes":[{"type":"text"}]}]}"#
    );
}

#[test]
fn transaction_deserialize_test() {
    let json = r#"{"operations":[{"op":"insert","path":[0,1],"nodes":[{"type":"text"}]}],"TextSelection":{"before_selection":{"start":{"path":[],"offset":0},"end":{"path":[],"offset":0}},"after_selection":{"start":{"path":[],"offset":0},"end":{"path":[],"offset":0}}}}"#;

    let transaction: Transaction = serde_json::from_str(json).unwrap();
    assert_eq!(transaction.operations.len(), 1);
}

#[test]
fn node_tree_deserialize_test() {
    let tree: NodeTree = serde_json::from_str(TREE_JSON).unwrap();
    assert_eq!(tree.number_of_children(None), 1);
}

#[test]
fn node_tree_serialize_test() {
    let tree: NodeTree = serde_json::from_str(TREE_JSON).unwrap();
    let json = serde_json::to_string_pretty(&tree).unwrap();
    assert_eq!(json, TREE_JSON);
}

#[allow(dead_code)]
const TREE_JSON: &str = r#"{
  "type": "editor",
  "children": [
    {
      "type": "image",
      "attributes": {
        "image_src": "https://s1.ax1x.com/2022/08/26/v2sSbR.jpg"
      }
    },
    {
      "type": "text",
      "attributes": {
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
    }
  ]
}"#;
