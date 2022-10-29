use crate::node::script::NodeScript::*;
use crate::node::script::{make_node_delta_changeset, NodeTest};

use lib_ot::core::{NodeData, NodeDataBuilder, Path};

#[test]
fn node_insert_test() {
    let mut test = NodeTest::new();
    let node_data = NodeData::new("text");
    let path: Path = vec![0].into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node_data: node_data.clone(),
            rev_id: 1,
        },
        AssertNode {
            path,
            expected: Some(node_data),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
#[should_panic]
fn node_insert_with_empty_path_test() {
    let mut test = NodeTest::new();
    let scripts = vec![InsertNode {
        path: vec![].into(),
        node_data: NodeData::new("text"),
        rev_id: 1,
    }];
    test.run_scripts(scripts);
}

#[test]
#[should_panic]
fn node_insert_with_not_exist_path_test() {
    let mut test = NodeTest::new();
    let node_data = NodeData::new("text");
    let path: Path = vec![0, 0, 9].into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node_data: node_data.clone(),
            rev_id: 1,
        },
        AssertNode {
            path,
            expected: Some(node_data),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn tree_insert_multiple_nodes_at_root_path_test() {
    let mut test = NodeTest::new();
    let node_1 = NodeData::new("a");
    let node_2 = NodeData::new("b");
    let node_3 = NodeData::new("c");
    let node_data_list = vec![node_1, node_2, node_3];
    let path: Path = vec![0].into();

    // Insert three nodes under the root
    let scripts = vec![
        // 0:a
        // 1:b
        // 2:c
        InsertNodes {
            path,
            node_data_list: node_data_list.clone(),
            rev_id: 1,
        },
        AssertNodesAtRoot {
            expected: node_data_list,
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn tree_insert_multiple_nodes_at_root_path_test2() {
    let mut test = NodeTest::new();
    let node_1 = NodeData::new("a");
    let node_2 = NodeData::new("b");
    let node_3 = NodeData::new("c");
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: node_1.clone(),
            rev_id: 1,
        },
        InsertNode {
            path: 1.into(),
            node_data: node_2.clone(),
            rev_id: 2,
        },
        InsertNode {
            path: 2.into(),
            node_data: node_3.clone(),
            rev_id: 3,
        },
        // 0:a
        // 1:b
        // 2:c
        AssertNode {
            path: 0.into(),
            expected: Some(node_1),
        },
        AssertNode {
            path: 1.into(),
            expected: Some(node_2),
        },
        AssertNode {
            path: 2.into(),
            expected: Some(node_3),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_node_with_children_test() {
    let mut test = NodeTest::new();
    let image_1 = NodeData::new("image_a");
    let image_2 = NodeData::new("image_b");

    let image = NodeDataBuilder::new("image")
        .add_node_data(image_1.clone())
        .add_node_data(image_2.clone())
        .build();
    let node_data = NodeDataBuilder::new("text").add_node_data(image.clone()).build();
    let path: Path = 0.into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node_data: node_data.clone(),
            rev_id: 1,
        },
        // 0:text
        //      0:image
        //             0:image_1
        //             1:image_2
        AssertNode {
            path,
            expected: Some(node_data),
        },
        AssertNode {
            path: vec![0, 0].into(),
            expected: Some(image),
        },
        AssertNode {
            path: vec![0, 0, 0].into(),
            expected: Some(image_1),
        },
        AssertNode {
            path: vec![0, 0, 1].into(),
            expected: Some(image_2),
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
        AssertNumberOfChildrenAtPath {
            path: None,
            expected: 4,
        },
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
            expected: Some(node_data_1_1),
        },
        AssertNode {
            path: vec![0, 1].into(),
            expected: Some(node_data_1_2),
        },
        AssertNode {
            path: vec![1, 0].into(),
            expected: Some(node_data_2_1),
        },
        AssertNode {
            path: vec![1, 1].into(),
            expected: Some(node_data_2_2),
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
            expected: Some(node_data_1_1),
        },
        AssertNode {
            path: vec![1, 1].into(),
            expected: Some(node_data_1_2),
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
            node_data: inserted_node,
            rev_id: 1,
        },
        DeleteNode {
            path: path.clone(),
            rev_id: 2,
        },
        AssertNode { path, expected: None },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_delete_node_from_list_test() {
    let mut test = NodeTest::new();
    let image_a = NodeData::new("image_a");
    let image_b = NodeData::new("image_b");

    let image_1 = NodeDataBuilder::new("image_1")
        .add_node_data(image_a.clone())
        .add_node_data(image_b.clone())
        .build();
    let text_node_1 = NodeDataBuilder::new("text_1").add_node_data(image_1).build();
    let image_2 = NodeDataBuilder::new("image_2")
        .add_node_data(image_a)
        .add_node_data(image_b)
        .build();
    let text_node_2 = NodeDataBuilder::new("text_2").add_node_data(image_2.clone()).build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_node_1,
            rev_id: 1,
        },
        InsertNode {
            path: 1.into(),
            node_data: text_node_2.clone(),
            rev_id: 2,
        },
        DeleteNode {
            path: 0.into(),
            rev_id: 3,
        },
        AssertNode {
            path: 1.into(),
            expected: None,
        },
        AssertNode {
            path: 0.into(),
            expected: Some(text_node_2),
        },
        AssertNode {
            path: vec![0, 0].into(),
            expected: Some(image_2),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_delete_nested_node_test() {
    let mut test = NodeTest::new();
    let image_a = NodeData::new("image_a");
    let image_b = NodeData::new("image_b");

    let image_1 = NodeDataBuilder::new("image_1")
        .add_node_data(image_a.clone())
        .add_node_data(image_b.clone())
        .build();
    let text_node_1 = NodeDataBuilder::new("text_1").add_node_data(image_1).build();

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
        // 1:text_2
        //      0:image_2
        //             0:image_a
        //             1:image_b
        DeleteNode {
            path: vec![0, 0, 0].into(),
            rev_id: 3,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_b
        // 1:text_2
        //      0:image_2
        //             0:image_a
        //             1:image_b
        AssertNode {
            path: vec![0, 0, 0].into(),
            expected: Some(image_b.clone()),
        },
        DeleteNode {
            path: vec![0, 0].into(),
            rev_id: 4,
        },
        // 0:text_1
        // 1:text_2
        //      0:image_2
        //             0:image_a
        //             1:image_b
        AssertNumberOfChildrenAtPath {
            path: Some(0.into()),
            expected: 0,
        },
        AssertNode {
            path: vec![0].into(),
            expected: Some(NodeDataBuilder::new("text_1").build()),
        },
        AssertNode {
            path: vec![1, 0, 0].into(),
            expected: Some(image_a),
        },
        AssertNode {
            path: vec![1, 0, 1].into(),
            expected: Some(image_b),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_delete_children_test() {
    let mut test = NodeTest::new();
    let inserted_node = NodeDataBuilder::new("text")
        .add_node_data(NodeDataBuilder::new("sub_text_1").build())
        .add_node_data(NodeDataBuilder::new("sub_text_2").build())
        .add_node_data(NodeDataBuilder::new("sub_text_3").build())
        .build();

    let scripts = vec![
        InsertNode {
            path: vec![0].into(),
            node_data: inserted_node,
            rev_id: 1,
        },
        AssertNode {
            path: vec![0, 0].into(),
            expected: Some(NodeDataBuilder::new("sub_text_1").build()),
        },
        AssertNode {
            path: vec![0, 1].into(),
            expected: Some(NodeDataBuilder::new("sub_text_2").build()),
        },
        AssertNode {
            path: vec![0, 2].into(),
            expected: Some(NodeDataBuilder::new("sub_text_3").build()),
        },
        AssertNumberOfChildrenAtPath {
            path: Some(Path(vec![0])),
            expected: 3,
        },
        DeleteNode {
            path: vec![0, 0].into(),
            rev_id: 2,
        },
        AssertNode {
            path: vec![0, 0].into(),
            expected: Some(NodeDataBuilder::new("sub_text_2").build()),
        },
        AssertNumberOfChildrenAtPath {
            path: Some(Path(vec![0])),
            expected: 2,
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_reorder_sub_nodes_test() {
    let mut test = NodeTest::new();
    let image_a = NodeData::new("image_a");
    let image_b = NodeData::new("image_b");

    let child_1 = NodeDataBuilder::new("image_1")
        .add_node_data(image_a.clone())
        .add_node_data(image_b.clone())
        .build();
    let text_node_1 = NodeDataBuilder::new("text_1").add_node_data(child_1).build();
    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_node_1,
            rev_id: 1,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_a
        //             1:image_b
        DeleteNode {
            path: vec![0, 0, 0].into(),
            rev_id: 2,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_b
        InsertNode {
            path: vec![0, 0, 1].into(),
            node_data: image_a.clone(),
            rev_id: 3,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_b
        //             1:image_a
        AssertNode {
            path: vec![0, 0, 0].into(),
            expected: Some(image_b),
        },
        AssertNode {
            path: vec![0, 0, 1].into(),
            expected: Some(image_a),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_reorder_nodes_test() {
    let mut test = NodeTest::new();
    let image_a = NodeData::new("image_a");
    let image_b = NodeData::new("image_b");

    let image_1 = NodeDataBuilder::new("image_1")
        .add_node_data(image_a.clone())
        .add_node_data(image_b.clone())
        .build();
    let text_node_1 = NodeDataBuilder::new("text_1").add_node_data(image_1.clone()).build();

    let image_2 = NodeDataBuilder::new("image_2")
        .add_node_data(image_a.clone())
        .add_node_data(image_b.clone())
        .build();
    let text_node_2 = NodeDataBuilder::new("text_2").add_node_data(image_2.clone()).build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: text_node_1.clone(),
            rev_id: 1,
        },
        InsertNode {
            path: 0.into(),
            node_data: text_node_2.clone(),
            rev_id: 1,
        },
        // 0:text_1
        //      0:image_1
        //             0:image_a
        //             1:image_b
        // 1:text_2
        //      0:image_2
        //             0:image_a
        //             1:image_b
        DeleteNode {
            path: vec![0].into(),
            rev_id: 3,
        },
        AssertNode {
            path: vec![0].into(),
            expected: Some(text_node_2.clone()),
        },
        InsertNode {
            path: vec![1].into(),
            node_data: text_node_1.clone(),
            rev_id: 4,
        },
        // 0:text_2
        //      0:image_2
        //             0:image_a
        //             1:image_b
        // 1:text_1
        //      0:image_1
        //             0:image_a
        //             1:image_b
        AssertNode {
            path: vec![0].into(),
            expected: Some(text_node_2),
        },
        AssertNode {
            path: vec![0, 0].into(),
            expected: Some(image_2),
        },
        AssertNode {
            path: vec![0, 0, 0].into(),
            expected: Some(image_a),
        },
        AssertNode {
            path: vec![1].into(),
            expected: Some(text_node_1),
        },
        AssertNode {
            path: vec![1, 0].into(),
            expected: Some(image_1),
        },
        AssertNode {
            path: vec![1, 0, 1].into(),
            expected: Some(image_b),
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_update_body_test() {
    let mut test = NodeTest::new();
    let (initial_delta, changeset, expected) = make_node_delta_changeset("Hello", "AppFlowy");
    let node = NodeDataBuilder::new("text").insert_delta(initial_delta).build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: node,
            rev_id: 1,
        },
        UpdateBody {
            path: 0.into(),
            changeset,
        },
        AssertNodeDelta {
            path: 0.into(),
            expected,
        },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_inverted_body_changeset_test() {
    let mut test = NodeTest::new();
    let (initial_delta, changeset, _expected) = make_node_delta_changeset("Hello", "AppFlowy");
    let node = NodeDataBuilder::new("text").insert_delta(initial_delta.clone()).build();

    let scripts = vec![
        InsertNode {
            path: 0.into(),
            node_data: node,
            rev_id: 1,
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset.clone(),
        },
        UpdateBody {
            path: 0.into(),
            changeset: changeset.inverted(),
        },
        AssertNodeDelta {
            path: 0.into(),
            expected: initial_delta,
        },
    ];
    test.run_scripts(scripts);
}
