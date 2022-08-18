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
    tb.insert_nodes(&Position(vec![0]), &vec![NodeData::new("type")]);
    let transaction = tb.finalize();
    document.apply(transaction);
}
