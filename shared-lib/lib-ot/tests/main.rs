use lib_ot::core::{DocumentTree, NodeData, Position, TransactionBuilder};
use std::collections::HashMap;

#[test]
fn main() {
    // Create a new arena
    let _document = DocumentTree::new();
}

#[test]
fn test_documents() {
    let mut document = DocumentTree::new();
    let mut tb = TransactionBuilder::new(&document);
    tb.insert_nodes(&vec![0].into(), &vec![NodeData::new("text")]);
    let transaction = tb.finalize();
    document.apply(transaction);

    assert!(document.node_at_path(&vec![0].into()).is_some());
    let node = document.node_at_path(&vec![0].into()).unwrap();
    let node_data = document.arena.get(node).unwrap().get();
    assert_eq!(node_data.node_type, "text");

    let mut tb = TransactionBuilder::new(&document);
    tb.update_attributes(
        &vec![0].into(),
        HashMap::from([("subtype".into(), Some("bullet-list".into()))]),
    );
    let transaction = tb.finalize();
    document.apply(transaction);

    let mut tb = TransactionBuilder::new(&document);
    tb.delete_node(&vec![0].into());
    let transaction = tb.finalize();
    document.apply(transaction);
    assert!(document.node_at_path(&vec![0].into()).is_none());
}

#[test]
fn test_inserts_nodes() {
    let mut document = DocumentTree::new();
    let transaction = {
        let mut tb = TransactionBuilder::new(&document);
        tb.insert_nodes(&vec![0].into(), &vec![NodeData::new("text")]);
        tb.insert_nodes(&vec![1].into(), &vec![NodeData::new("text")]);
        tb.insert_nodes(&vec![2].into(), &vec![NodeData::new("text")]);
        tb.finalize()
    };
    document.apply(transaction);

    let transaction = {
        let mut tb = TransactionBuilder::new(&document);
        tb.insert_nodes(&vec![1].into(), &vec![NodeData::new("text")]);
        tb.finalize()
    };
    document.apply(transaction);
}

#[test]
fn test_update_nodes() {
    let mut document = DocumentTree::new();
    let transaction = {
        let mut tb = TransactionBuilder::new(&document);
        tb.insert_nodes(&vec![0].into(), &vec![NodeData::new("text")]);
        tb.insert_nodes(&vec![1].into(), &vec![NodeData::new("text")]);
        tb.insert_nodes(&vec![2].into(), &vec![NodeData::new("text")]);
        tb.finalize()
    };
    document.apply(transaction);

    let transaction = {
        let mut tb = TransactionBuilder::new(&document);
        tb.update_attributes(&vec![1].into(), HashMap::from([
            ("bolded".into(), Some("true".into())),
        ]));
        tb.finalize()
    };
    document.apply(transaction);

    let node = document.node_at_path(&Position(vec![1])).unwrap();
    let node_data = document.arena.get(node).unwrap().get();
    let is_bold = node_data.attributes.borrow().0.get("bolded").unwrap().clone();
    assert_eq!(is_bold.unwrap(), "true");
}
