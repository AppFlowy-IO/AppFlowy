use lib_ot::core::{
    AttributeBuilder, Changeset, Extension, Interval, NodeData, NodeDataBuilder, NodeOperation, Path, Transaction,
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
        .add_node(NodeData::new("sub_text".to_owned()))
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
        r#"{"op":"update","path":[0,1],"new":{"bold":true},"old":{"bold":null}}"#
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
        r#"{"op":"update","path":[0,1],"delta":[{"insert":"AppFlowy..."}],"inverted":[{"delete":11}]}"#
    );
}

#[test]
fn operation_update_node_body_deserialize_test() {
    let json_1 = r#"{"op":"update","path":[0,1],"delta":[{"insert":"AppFlowy..."}],"inverted":[{"delete":11}]}"#;
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
    transaction.extension = Extension::TextSelection {
        before_selection: Interval::new(0, 1),
        after_selection: Interval::new(1, 2),
    };
    let json = serde_json::to_string(&transaction).unwrap();
    assert_eq!(
        json,
        r#"{"operations":[{"op":"insert","path":[0,1],"nodes":[{"type":"text"}]}],"TextSelection":{"before_selection":{"start":0,"end":1},"after_selection":{"start":1,"end":2}}}"#
    );
}

#[test]
fn transaction_deserialize_test() {
    let json = r#"{"operations":[{"op":"insert","path":[0,1],"nodes":[{"type":"text"}]}],"TextSelection":{"before_selection":{"start":0,"end":1},"after_selection":{"start":1,"end":2}}}"#;
    let transaction: Transaction = serde_json::from_str(json).unwrap();
    assert_eq!(transaction.operations.len(), 1);
}
