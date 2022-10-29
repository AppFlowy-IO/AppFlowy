use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;

use lib_ot::core::{Changeset, NodeData, NodeDataBuilder, NodeOperation, Path};

#[test]
fn operation_delete_nested_node_test() {
    let mut test = NodeTest::new();
    let image_a = NodeData::new("image_a");
    let image_b = NodeData::new("image_b");

    let video_a = NodeData::new("video_a");
    let video_b = NodeData::new("video_b");

    let image_1 = NodeDataBuilder::new("image_1")
        .add_node_data(image_a.clone())
        .add_node_data(image_b.clone())
        .build();
    let video_1 = NodeDataBuilder::new("video_1")
        .add_node_data(video_a.clone())
        .add_node_data(video_b.clone())
        .build();

    let text_node_1 = NodeDataBuilder::new("text_1")
        .add_node_data(image_1)
        .add_node_data(video_1.clone())
        .build();

    let image_2 = NodeDataBuilder::new("image_2")
        .add_node_data(image_a.clone())
        .add_node_data(image_b.clone())
        .build();
    let text_node_2 = NodeDataBuilder::new("text_2").add_node_data(image_2).build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_node_1,
            rev_id: 1,
        },
        InsertNode {
            path: 1.into(),
            node_data: text_node_2,
            rev_id: 2,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_a
        //             1:image_b
        //      1:video_1
        //             0:video_a
        //             1:video_b
        // 1:text_2
        //      0:image_2
        //             0:image_a
        //             1:image_b
        DeleteNode {
            path: vec![0, 0, 0].into(),
            rev_id: 3,
        },
        AssertNode {
            path: vec![0, 0, 0].into(),
            expected: Some(image_b),
        },
        AssertNode {
            path: vec![0, 1].into(),
            expected: Some(video_1.clone()),
        },
        DeleteNode {
            path: vec![0, 1, 1].into(),
            rev_id: 4,
        },
        AssertNode {
            path: vec![0, 1, 0].into(),
            expected: Some(video_a.clone()),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn operation_delete_node_with_revision_conflict_test() {
    let mut test = NodeTest::new();
    let text_1 = NodeDataBuilder::new("text_1").build();
    let text_2 = NodeDataBuilder::new("text_2").build();
    let text_3 = NodeDataBuilder::new("text_3").build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_1.clone(),
            rev_id: 1,
        },
        InsertNode {
            path: 1.into(),
            node_data: text_2,
            rev_id: 2,
        },
        // The node's in the tree will be:
        // 0: text_1
        // 2: text_2
        //
        // The insert action is happened concurrently with the delete action, because they
        // share the same rev_id. aka, 3. The delete action is want to delete the node at index 1,
        // but it was moved to index 2.
        InsertNode {
            path: 1.into(),
            node_data: text_3.clone(),
            rev_id: 3,
        },
        // 0: text_1
        // 1: text_3
        // 2: text_2
        //
        // The path of the delete action will be transformed to a new path that point to the text_2.
        // 1 -> 2
        DeleteNode {
            path: 1.into(),
            rev_id: 3,
        },
        // After perform the delete action, the tree will be:
        // 0: text_1
        // 1: text_3
        AssertNumberOfChildrenAtPath {
            path: None,
            expected: 2,
        },
        AssertNode {
            path: 0.into(),
            expected: Some(text_1),
        },
        AssertNode {
            path: 1.into(),
            expected: Some(text_3),
        },
        AssertNode {
            path: 2.into(),
            expected: None,
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn operation_update_node_after_delete_test() {
    let mut test = NodeTest::new();
    let text_1 = NodeDataBuilder::new("text_1").build();
    let text_2 = NodeDataBuilder::new("text_2").build();
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_1.clone(),
            rev_id: 1,
        },
        InsertNode {
            path: 1.into(),
            node_data: text_2,
            rev_id: 2,
        },
        DeleteNode {
            path: 0.into(),
            rev_id: 3,
        },
        // The node at path 1 is not exist. The following UpdateBody script will do nothing
        AssertNode {
            path: 1.into(),
            expected: None,
        },
        UpdateBody {
            path: 1.into(),
            changeset: Changeset::Delta {
                delta: Default::default(),
                inverted: Default::default(),
            },
        },
    ];
    test.run_scripts(scripts);
}
