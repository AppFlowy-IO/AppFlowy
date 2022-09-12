use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;
use lib_ot::core::NodeBody;
use lib_ot::core::NodeBodyChangeset;
use lib_ot::core::OperationTransform;
use lib_ot::core::{NodeData, NodeDataBuilder, Path};
use lib_ot::text_delta::TextDeltaBuilder;

#[test]
fn node_insert_test() {
    let mut test = NodeTest::new();
    let inserted_node = NodeData::new("text");
    let path: Path = 0.into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node: inserted_node.clone(),
        },
        AssertNode {
            path,
            expected: Some(inserted_node),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_node_with_children_test() {
    let mut test = NodeTest::new();
    let inserted_node = NodeDataBuilder::new("text").add_node(NodeData::new("image")).build();
    let path: Path = 0.into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node: inserted_node.clone(),
        },
        AssertNode {
            path,
            expected: Some(inserted_node),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_multi_nodes_test() {
    let mut test = NodeTest::new();
    let path_1: Path = 0.into();
    let node_1 = NodeData::new("text_1");

    let path_2: Path = 1.into();
    let node_2 = NodeData::new("text_2");

    let path_3: Path = 2.into();
    let node_3 = NodeData::new("text_3");

    let scripts = vec![
        InsertNode {
            path: path_1.clone(),
            node: node_1.clone(),
        },
        InsertNode {
            path: path_2.clone(),
            node: node_2.clone(),
        },
        InsertNode {
            path: path_3.clone(),
            node: node_3.clone(),
        },
        AssertNode {
            path: path_1,
            expected: Some(node_1),
        },
        AssertNode {
            path: path_2,
            expected: Some(node_2),
        },
        AssertNode {
            path: path_3,
            expected: Some(node_3),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_node_in_ordered_nodes_test() {
    let mut test = NodeTest::new();
    let path_1: Path = 0.into();
    let node_1 = NodeData::new("text_1");

    let path_2: Path = 1.into();
    let node_2_1 = NodeData::new("text_2_1");
    let node_2_2 = NodeData::new("text_2_2");

    let path_3: Path = 2.into();
    let node_3 = NodeData::new("text_3");

    let path_4: Path = 3.into();

    let scripts = vec![
        InsertNode {
            path: path_1.clone(),
            node: node_1.clone(),
        },
        InsertNode {
            path: path_2.clone(),
            node: node_2_1.clone(),
        },
        InsertNode {
            path: path_3.clone(),
            node: node_3.clone(),
        },
        // 0:note_1 , 1: note_2_1, 2: note_3
        InsertNode {
            path: path_2.clone(),
            node: node_2_2.clone(),
        },
        // 0:note_1 , 1:note_2_2,  2: note_2_1, 3: note_3
        AssertNode {
            path: path_1,
            expected: Some(node_1),
        },
        AssertNode {
            path: path_2,
            expected: Some(node_2_2),
        },
        AssertNode {
            path: path_3,
            expected: Some(node_2_1),
        },
        AssertNode {
            path: path_4,
            expected: Some(node_3),
        },
        AssertNumberOfNodesAtPath { path: None, len: 4 },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_with_attributes_test() {
    let mut test = NodeTest::new();
    let path: Path = 0.into();
    let mut inserted_node = NodeData::new("text");
    inserted_node.attributes.insert("bold", true);
    inserted_node.attributes.insert("underline", true);

    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node: inserted_node.clone(),
        },
        UpdateAttributes {
            path: path.clone(),
            attributes: inserted_node.attributes.clone(),
        },
        AssertNode {
            path,
            expected: Some(inserted_node),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_delete_test() {
    let mut test = NodeTest::new();
    let inserted_node = NodeData::new("text");

    let path: Path = 0.into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node: inserted_node,
        },
        DeleteNode { path: path.clone() },
        AssertNode { path, expected: None },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_update_body_test() {
    let mut test = NodeTest::new();
    let path: Path = 0.into();

    let s = "Hello".to_owned();
    let init_delta = TextDeltaBuilder::new().insert(&s).build();
    let delta = TextDeltaBuilder::new().retain(s.len()).insert(" AppFlowy").build();
    let inverted = delta.invert(&init_delta);
    let expected = init_delta.compose(&delta).unwrap();

    let node = NodeDataBuilder::new("text")
        .insert_body(NodeBody::Delta(init_delta))
        .build();

    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node,
        },
        UpdateBody {
            path: path.clone(),
            changeset: NodeBodyChangeset::Delta { delta, inverted },
        },
        AssertNodeDelta { path, expected },
    ];
    test.run_scripts(scripts);
}
