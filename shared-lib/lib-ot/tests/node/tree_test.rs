use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;
use lib_ot::core::Body;
use lib_ot::core::Changeset;
use lib_ot::core::OperationTransform;
use lib_ot::core::{NodeData, NodeDataBuilder, Path};
use lib_ot::text_delta::TextOperationBuilder;

#[test]
fn node_insert_test() {
    let mut test = NodeTest::new();
    let inserted_node = NodeData::new("text");
    let path: Path = 0.into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node_data: inserted_node.clone(),
            rev_id: 1,
        },
        AssertNodeData {
            path,
            expected: Some(inserted_node),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_node_with_children_test() {
    let mut test = NodeTest::new();
    let inserted_node = NodeDataBuilder::new("text")
        .add_node_data(NodeData::new("image"))
        .build();
    let path: Path = 0.into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node_data: inserted_node.clone(),
            rev_id: 1,
        },
        AssertNodeData {
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
            node_data: node_1.clone(),
            rev_id: 1,
        },
        InsertNode {
            path: path_2.clone(),
            node_data: node_2.clone(),
            rev_id: 2,
        },
        InsertNode {
            path: path_3.clone(),
            node_data: node_3.clone(),
            rev_id: 3,
        },
        AssertNodeData {
            path: path_1,
            expected: Some(node_1),
        },
        AssertNodeData {
            path: path_2,
            expected: Some(node_2),
        },
        AssertNodeData {
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

    let scripts = vec![
        InsertNode {
            path: path_1.clone(),
            node_data: node_1.clone(),
            rev_id: 1,
        },
        InsertNode {
            path: path_2.clone(),
            node_data: node_2_1.clone(),
            rev_id: 2,
        },
        InsertNode {
            path: path_3.clone(),
            node_data: node_3,
            rev_id: 3,
        },
        // 0:text_1
        // 1:text_2_1
        // 2:text_3
        InsertNode {
            path: path_2.clone(),
            node_data: node_2_2.clone(),
            rev_id: 4,
        },
        // 0:text_1
        // 1:text_2_2
        // 2:text_2_1
        // 3:text_3
        AssertNodeData {
            path: path_1,
            expected: Some(node_1),
        },
        AssertNodeData {
            path: path_2,
            expected: Some(node_2_2),
        },
        AssertNodeData {
            path: path_3,
            expected: Some(node_2_1),
        },
        AssertNumberOfNodesAtPath { path: None, len: 4 },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_nested_nodes_test() {
    let mut test = NodeTest::new();
    let node_data_1_1 = NodeDataBuilder::new("text_1_1").build();
    let node_data_1_2 = NodeDataBuilder::new("text_1_2").build();
    let node_data_1 = NodeDataBuilder::new("text_1")
        .add_node_data(node_data_1_1.clone())
        .add_node_data(node_data_1_2.clone())
        .build();

    let node_data_2_1 = NodeDataBuilder::new("text_2_1").build();
    let node_data_2_2 = NodeDataBuilder::new("text_2_2").build();
    let node_data_2 = NodeDataBuilder::new("text_2")
        .add_node_data(node_data_2_1.clone())
        .add_node_data(node_data_2_2.clone())
        .build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: node_data_1,
            rev_id: 1,
        },
        InsertNode {
            path: 1.into(),
            node_data: node_data_2,
            rev_id: 2,
        },
        // the tree will be:
        // 0:text_1
        //      0:text_1_1
        //      1:text_1_2
        // 1:text_2
        //      0:text_2_1
        //      1:text_2_2
        AssertNode {
            path: vec![0, 0].into(),
            expected: Some(node_data_1_1.into()),
        },
        AssertNode {
            path: vec![0, 1].into(),
            expected: Some(node_data_1_2.into()),
        },
        AssertNode {
            path: vec![1, 0].into(),
            expected: Some(node_data_2_1.into()),
        },
        AssertNode {
            path: vec![1, 1].into(),
            expected: Some(node_data_2_2.into()),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_node_before_existing_nested_nodes_test() {
    let mut test = NodeTest::new();
    let node_data_1_1 = NodeDataBuilder::new("text_1_1").build();
    let node_data_1_2 = NodeDataBuilder::new("text_1_2").build();
    let node_data_1 = NodeDataBuilder::new("text_1")
        .add_node_data(node_data_1_1.clone())
        .add_node_data(node_data_1_2.clone())
        .build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: node_data_1,
            rev_id: 1,
        },
        // 0:text_1
        //      0:text_1_1
        //      1:text_1_2
        InsertNode {
            path: 0.into(),
            node_data: NodeDataBuilder::new("text_0").build(),
            rev_id: 2,
        },
        // 0:text_0
        // 1:text_1
        //      0:text_1_1
        //      1:text_1_2
        AssertNode {
            path: vec![1, 0].into(),
            expected: Some(node_data_1_1.into()),
        },
        AssertNode {
            path: vec![1, 1].into(),
            expected: Some(node_data_1_2.into()),
        },
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
            node_data: inserted_node.clone(),
            rev_id: 1,
        },
        UpdateAttributes {
            path: path.clone(),
            attributes: inserted_node.attributes.clone(),
        },
        AssertNodeData {
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
            node_data: inserted_node,
            rev_id: 1,
        },
        DeleteNode {
            path: path.clone(),
            rev_id: 2,
        },
        AssertNodeData { path, expected: None },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_update_body_test() {
    let mut test = NodeTest::new();
    let path: Path = 0.into();

    let s = "Hello".to_owned();
    let init_delta = TextOperationBuilder::new().insert(&s).build();
    let delta = TextOperationBuilder::new().retain(s.len()).insert(" AppFlowy").build();
    let inverted = delta.invert(&init_delta);
    let expected = init_delta.compose(&delta).unwrap();

    let node = NodeDataBuilder::new("text")
        .insert_body(Body::Delta(init_delta))
        .build();

    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node_data: node,
            rev_id: 1,
        },
        UpdateBody {
            path: path.clone(),
            changeset: Changeset::Delta { delta, inverted },
        },
        AssertNodeDelta { path, expected },
    ];
    test.run_scripts(scripts);
}
