use std::collections::HashMap;
use lib_ot::core::{DocumentTree, NodeData, Position, TransactionBuilder};

#[test]
fn main() {
    // Create a new arena
    let _document = DocumentTree::new();
}

#[test]
fn test_documents() {
    let mut document = DocumentTree::new();
    let mut tb = TransactionBuilder::new(&document);
    tb.insert_nodes(&Position(vec![0]), &vec![NodeData::new("text")]);
    let transaction = tb.finalize();
    document.apply(transaction);

    assert!(document.node_at_path(&Position(vec![0])).is_some());
    let node = document.node_at_path(&Position(vec![0])).unwrap();
    let node_data = document.arena.get(node).unwrap().get();
    assert_eq!(node_data.node_type, "text");

    let mut tb = TransactionBuilder::new(&document);
    tb.update_attributes(&Position(vec![0]), HashMap::from([
        ("subtype".into(), Some("bullet-list".into())),
    ]));
    let transaction = tb.finalize();
    document.apply(transaction);
}
