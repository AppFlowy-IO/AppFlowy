use crate::core::{DocumentOperation, DocumentTree};

pub struct Transaction {
    pub operations: Vec<DocumentOperation>,
}

impl Transaction {

    fn new(operations: Vec<DocumentOperation>) -> Transaction {
        Transaction {
            operations,
        }
    }

}

pub struct TransactionBuilder<'a> {
    document: &'a DocumentTree,
    operations: Vec<DocumentOperation>,
}

impl<'a> TransactionBuilder<'a> {
    pub fn new(document: &'a DocumentTree) -> TransactionBuilder {
        TransactionBuilder {
            document,
            operations: Vec::new()
        }
    }

    pub fn push(&mut self, op: DocumentOperation) {
        self.operations.push(op);
    }

    pub fn finalize(self) -> Transaction {
        Transaction {
            operations: self.operations,
        }
    }
}
