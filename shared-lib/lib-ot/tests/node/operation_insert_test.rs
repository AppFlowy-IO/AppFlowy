use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;

use lib_ot::core::{placeholder_node, NodeData, NodeDataBuilder, NodeOperation, Path};

#[test]
fn operation_insert_op_transform_test() {
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

    op_1.transform(&mut insert_2);
    let json = serde_json::to_string(&insert_2).unwrap();
    assert_eq!(json, r#"{"op":"insert","path":[0,2],"nodes":[{"type":"text_2"}]}"#);
}

#[test]
fn operation_insert_one_level_path_test() {
    let node_data_1 = NodeDataBuilder::new("text_1").build();
    let node_data_2 = NodeDataBuilder::new("text_2").build();
    let node_data_3 = NodeDataBuilder::new("text_3").build();
    let node_3 = node_data_3.clone();
    //  0: text_1
    //  1: text_2
    //
    //  Insert a new operation with rev_id 2 to index 1,but the index was already taken, so
    //  it needs to be transformed.
    //
    //  0: text_1
    //  1: text_2
    //  2: text_3
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
            rev_id: 2,
        },
        AssertNode {
            path: 2.into(),
            expected: Some(node_3.clone()).clone(),
        },
    ];
    NodeTest::new().run_scripts(scripts);

    //  If the rev_id of the node_data_3 is 3. then the tree will be:
    //  0: text_1
    //  1: text_3
    //  2: text_2
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
        InsertNode {
            path: 1.into(),
            node_data: node_data_3,
            rev_id: 3,
        },
        AssertNode {
            path: 1.into(),
            expected: Some(node_3),
        },
    ];
    NodeTest::new().run_scripts(scripts);
}

#[test]
fn operation_insert_with_multiple_level_path_test() {
    let mut test = NodeTest::new();
    let node_data_1 = NodeDataBuilder::new("text_1")
        .add_node_data(NodeDataBuilder::new("text_1_1").build())
        .add_node_data(NodeDataBuilder::new("text_1_2").build())
        .build();

    let node_data_2 = NodeDataBuilder::new("text_2")
        .add_node_data(NodeDataBuilder::new("text_2_1").build())
        .add_node_data(NodeDataBuilder::new("text_2_2").build())
        .build();

    let node_data_3 = NodeDataBuilder::new("text_3").build();
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
        InsertNode {
            path: 1.into(),
            node_data: node_data_3.clone(),
            rev_id: 2,
        },
        AssertNode {
            path: 2.into(),
            expected: Some(node_data_3),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn operation_insert_node_when_its_parent_is_not_exist_test() {
    let mut test = NodeTest::new();
    let text_1 = NodeDataBuilder::new("text_1").build();
    let text_2 = NodeDataBuilder::new("text_2").build();
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_1.clone(),
            rev_id: 1,
        },
        // The node at path 1 is not existing when inserting the text_2 to path 2.
        InsertNode {
            path: 2.into(),
            node_data: text_2.clone(),
            rev_id: 2,
        },
        AssertNode {
            path: 1.into(),
            expected: Some(placeholder_node()),
        },
        AssertNode {
            path: 2.into(),
            expected: Some(text_2),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn operation_insert_node_out_of_bound_test() {
    let mut test = NodeTest::new();
    let image_a = NodeData::new("image_a");
    let image_b = NodeData::new("image_b");
    let image = NodeDataBuilder::new("image_1")
        .add_node_data(image_a)
        .add_node_data(image_b)
        .build();
    let text_node = NodeDataBuilder::new("text_1").add_node_data(image).build();
    let image_c = NodeData::new("image_c");

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_node,
            rev_id: 1,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_a
        //             1:image_b
        InsertNode {
            path: vec![0, 0, 3].into(),
            node_data: image_c.clone(),
            rev_id: 2,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_a
        //             1:image_b
        //             2:placeholder node
        //             3:image_c
        AssertNode {
            path: vec![0, 0, 2].into(),
            expected: Some(placeholder_node()),
        },
        AssertNode {
            path: vec![0, 0, 3].into(),
            expected: Some(image_c),
        },
        AssertNode {
            path: vec![0, 0, 10].into(),
            expected: None,
        },
    ];
    test.run_scripts(scripts);
}
#[test]
fn operation_insert_node_when_its_parent_is_not_exist_test2() {
    let mut test = NodeTest::new();
    let text_1 = NodeDataBuilder::new("text_1").build();
    let text_2 = NodeDataBuilder::new("text_2").build();
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_1.clone(),
            rev_id: 1,
        },
        // The node at path 1 is not existing when inserting the text_2 to path 2.
        InsertNode {
            path: 3.into(),
            node_data: text_2.clone(),
            rev_id: 2,
        },
        AssertNode {
            path: 1.into(),
            expected: Some(placeholder_node()),
        },
        AssertNode {
            path: 2.into(),
            expected: Some(placeholder_node()),
        },
        AssertNode {
            path: 3.into(),
            expected: Some(text_2),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
#[should_panic]
fn operation_insert_node_when_its_parent_is_not_exist_test3() {
    let mut test = NodeTest::new();
    let text_1 = NodeDataBuilder::new("text_1").build();
    let text_2 = NodeDataBuilder::new("text_2").build();
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_1.clone(),
            rev_id: 1,
        },
        // The node at path 1 is not existing when inserting the text_2 to path 2.
        InsertNode {
            path: vec![1, 0].into(),
            node_data: text_2.clone(),
            rev_id: 2,
        },
        AssertNode {
            path: 1.into(),
            expected: Some(placeholder_node()),
        },
        AssertNode {
            path: vec![1, 0].into(),
            expected: Some(text_2),
        },
    ];
    test.run_scripts(scripts);
}
