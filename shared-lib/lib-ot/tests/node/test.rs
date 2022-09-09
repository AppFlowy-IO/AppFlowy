use crate::node::script::NodeScript::*;
use crate::node::script::NodeTest;
use lib_ot::core::{NodeAttributes, NodeSubTree, Path};

#[test]
fn node_insert_test() {
    let mut test = NodeTest::new();
    let inserted_node = NodeSubTree::new("text");
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
    let inserted_node = NodeSubTree {
        note_type: "text".into(),
        attributes: NodeAttributes::new(),
        delta: None,
        children: vec![NodeSubTree::new("image")],
    };
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
    let node_1 = NodeSubTree::new("text_1");

    let path_2: Path = 1.into();
    let node_2 = NodeSubTree::new("text_2");

    let path_3: Path = 2.into();
    let node_3 = NodeSubTree::new("text_3");

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
    let node_1 = NodeSubTree::new("text_1");

    let path_2: Path = 1.into();
    let node_2_1 = NodeSubTree::new("text_2_1");
    let node_2_2 = NodeSubTree::new("text_2_2");

    let path_3: Path = 2.into();
    let node_3 = NodeSubTree::new("text_3");

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
        AssertNumberOfChildrenAtPath { path: None, len: 4 },
    ];
    test.run_scripts(scripts);
}

#[test]
fn node_insert_with_attributes_test() {
    let mut test = NodeTest::new();
    let path: Path = 0.into();
    let mut inserted_node = NodeSubTree::new("text");
    inserted_node.attributes.insert("bold".to_string(), Some("true".into()));
    inserted_node
        .attributes
        .insert("underline".to_string(), Some("true".into()));

    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node: inserted_node.clone(),
        },
        InsertAttributes {
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
    let inserted_node = NodeSubTree::new("text");

    let path: Path = 0.into();
    let scripts = vec![
        InsertNode {
            path: path.clone(),
            node: inserted_node.clone(),
        },
        DeleteNode { path: path.clone() },
        AssertNode { path, expected: None },
    ];
    test.run_scripts(scripts);
}
