use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;
use lib_ot::core::{AttributeBuilder, Node, NodeTree, Transaction, TransactionBuilder};
use lib_ot::{
    core::{NodeBodyChangeset, NodeData, NodeDataBuilder, NodeOperation, Path},
    text_delta::TextDeltaBuilder,
};

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
    let operation = NodeOperation::UpdateAttributes {
        path: Path(vec![0, 1]),
        attributes: AttributeBuilder::new().insert("bold", true).build(),
        old_attributes: AttributeBuilder::new().insert("bold", false).build(),
    };

    let result = serde_json::to_string(&operation).unwrap();

    assert_eq!(
        result,
        r#"{"op":"update","path":[0,1],"attributes":{"bold":true},"oldAttributes":{"bold":null}}"#
    );
}

#[test]
fn operation_update_node_body_serialize_test() {
    let delta = TextDeltaBuilder::new().insert("AppFlowy...").build();
    let inverted = delta.invert_str("");
    let changeset = NodeBodyChangeset::Delta { delta, inverted };
    let insert = NodeOperation::UpdateBody {
        path: Path(vec![0, 1]),
        changeset,
    };
    let result = serde_json::to_string(&insert).unwrap();
    assert_eq!(
        result,
        r#"{"op":"update-body","path":[0,1],"changeset":{"delta":{"delta":[{"insert":"AppFlowy..."}],"inverted":[{"delete":11}]}}}"#
    );
    //
}

#[test]
fn operation_update_node_body_deserialize_test() {
    let json_1 = r#"{"op":"update-body","path":[0,1],"changeset":{"delta":{"delta":[{"insert":"AppFlowy..."}],"inverted":[{"delete":11}]}}}"#;
    let operation: NodeOperation = serde_json::from_str(json_1).unwrap();
    let json_2 = serde_json::to_string(&operation).unwrap();
    assert_eq!(json_1, json_2);
}

#[test]
fn operation_insert_transform_test() {
    let node_1 = NodeDataBuilder::new("text_1").build();
    let node_2 = NodeDataBuilder::new("text_2").build();
    let op_1 = NodeOperation::Insert {
        path: Path(vec![0, 1]),
        nodes: vec![node_1],
    };

    let mut insert_2 = NodeOperation::Insert {
        path: Path(vec![0, 1]),
        nodes: vec![node_2],
    };

    // let mut node_tree = NodeTree::new("root");
    // node_tree.apply_op(insert_1.clone()).unwrap();

    let new_op = op_1.transform(&insert_2);
    let json = serde_json::to_string(&new_op).unwrap();
    assert_eq!(json, r#"{"op":"insert","path":[0,2],"nodes":[{"type":"text_2"}]}"#);
}

#[test]
fn operation_insert_transform_test2() {
    let mut test = NodeTest::new();
    let node_data_1 = NodeDataBuilder::new("text_1").build();
    let node_data_2 = NodeDataBuilder::new("text_2").build();
    let node_2: Node = node_data_2.clone().into();
    let node_data_3 = NodeDataBuilder::new("text_3").build();
    let node_3: Node = node_data_3.clone().into();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: node_data_1.clone(),
            rev_id: 1,
        },
        InsertNode {
            path: 1.into(),
            node_data: node_data_2.clone(),
            rev_id: 2,
        },
        InsertNode {
            path: 1.into(),
            node_data: node_data_3.clone(),
            rev_id: 1,
        },
        // AssertNode {
        //     path: 2.into(),
        //     expected: node_2,
        // },
        AssertNode {
            path: 1.into(),
            expected: node_3,
        },
    ];
    test.run_scripts(scripts);
}
