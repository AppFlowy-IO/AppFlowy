use lib_ot::core::{DocumentTree, TransactionBuilder};

#[test]
fn main() {
    // Create a new arena
    let _document = DocumentTree::new();
}

#[test]
fn test_documents() {
    let mut document = DocumentTree::new();
    let tb = TransactionBuilder::new();
    document.apply(tb.finalize());
}
