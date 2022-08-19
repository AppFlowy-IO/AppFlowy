use std::collections::HashMap;
use lib_ot::core::{DocumentTree, NodeData, TransactionBuilder};

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
    tb.update_attributes(&vec![0].into(), HashMap::from([
        ("subtype".into(), Some("bullet-list".into())),
    ]));
    let transaction = tb.finalize();
    document.apply(transaction);

    let mut tb = TransactionBuilder::new(&document);
    tb.delete_node(&vec![0].into());
    let transaction = tb.finalize();
    document.apply(transaction);
    assert!(document.node_at_path(&vec![0].into()).is_none());
}
