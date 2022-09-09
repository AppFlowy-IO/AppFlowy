use lib_ot::core::{DocumentTree, NodeAttributes, NodeSubTree, Path, TransactionBuilder};
use lib_ot::errors::OTErrorCode;
use std::collections::HashMap;

#[test]
fn main() {
    // Create a new arena
    let _document = DocumentTree::new();
}

#[test]
fn test_documents() {
    let mut document = DocumentTree::new();
    let transaction = TransactionBuilder::new(&document)
        .insert_node_at_path(0, NodeSubTree::new("text"))
        .finalize();

    document.apply(transaction).unwrap();

    assert!(document.node_at_path(0).is_some());
    let node = document.node_at_path(0).unwrap();
    let node_data = document.get_node_data(node).unwrap();
    assert_eq!(node_data.node_type, "text");

    let transaction = TransactionBuilder::new(&document)
        .update_attributes_at_path(
            &vec![0].into(),
            HashMap::from([("subtype".into(), Some("bullet-list".into()))]),
        )
        .finalize();
    document.apply(transaction).unwrap();

    let transaction = TransactionBuilder::new(&document)
        .delete_node_at_path(&vec![0].into())
        .finalize();
    document.apply(transaction).unwrap();
    assert!(document.node_at_path(0).is_none());
}

#[test]
fn test_inserts_nodes() {
    let mut document = DocumentTree::new();
    let transaction = TransactionBuilder::new(&document)
        .insert_node_at_path(0, NodeSubTree::new("text"))
        .insert_node_at_path(1, NodeSubTree::new("text"))
        .insert_node_at_path(2, NodeSubTree::new("text"))
        .finalize();
    document.apply(transaction).unwrap();

    let transaction = TransactionBuilder::new(&document)
        .insert_node_at_path(1, NodeSubTree::new("text"))
        .finalize();
    document.apply(transaction).unwrap();
}

#[test]
fn test_inserts_subtrees() {
    let mut document = DocumentTree::new();
    let transaction = TransactionBuilder::new(&document)
        .insert_node_at_path(
            0,
            NodeSubTree {
                note_type: "text".into(),
                attributes: NodeAttributes::new(),
                delta: None,
                children: vec![NodeSubTree::new("image")],
            },
        )
        .finalize();
    document.apply(transaction).unwrap();

    let node = document.node_at_path(&Path(vec![0, 0])).unwrap();
    let data = document.get_node_data(node).unwrap();
    assert_eq!(data.node_type, "image");
}

#[test]
fn test_update_nodes() {
    let mut document = DocumentTree::new();
    let transaction = TransactionBuilder::new(&document)
        .insert_node_at_path(&vec![0], NodeSubTree::new("text"))
        .insert_node_at_path(&vec![1], NodeSubTree::new("text"))
        .insert_node_at_path(vec![2], NodeSubTree::new("text"))
        .finalize();
    document.apply(transaction).unwrap();

    let transaction = TransactionBuilder::new(&document)
        .update_attributes_at_path(&vec![1].into(), HashMap::from([("bolded".into(), Some("true".into()))]))
        .finalize();
    document.apply(transaction).unwrap();

    let node = document.node_at_path(&Path(vec![1])).unwrap();
    let node_data = document.get_node_data(node).unwrap();
    let is_bold = node_data.attributes.0.get("bolded").unwrap().clone();
    assert_eq!(is_bold.unwrap(), "true");
}

#[test]
fn test_delete_nodes() {
    let mut document = DocumentTree::new();
    let transaction = TransactionBuilder::new(&document)
        .insert_node_at_path(0, NodeSubTree::new("text"))
        .insert_node_at_path(1, NodeSubTree::new("text"))
        .insert_node_at_path(2, NodeSubTree::new("text"))
        .finalize();
    document.apply(transaction).unwrap();

    let transaction = TransactionBuilder::new(&document)
        .delete_node_at_path(&Path(vec![1]))
        .finalize();
    document.apply(transaction).unwrap();

    let len = document.number_of_children();
    assert_eq!(len, 2);
}

#[test]
fn test_errors() {
    let mut document = DocumentTree::new();
    let transaction = TransactionBuilder::new(&document)
        .insert_node_at_path(0, NodeSubTree::new("text"))
        .insert_node_at_path(100, NodeSubTree::new("text"))
        .finalize();
    let result = document.apply(transaction);
    assert_eq!(result.err().unwrap().code, OTErrorCode::PathNotFound);
}
