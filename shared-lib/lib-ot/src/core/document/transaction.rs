use crate::core::DocumentOperation;

pub struct Transaction {
    pub operations: Vec<DocumentOperation>,
}

pub struct TransactionBuilder {
    operations: Vec<DocumentOperation>,
}

impl TransactionBuilder {
    pub fn new() -> TransactionBuilder {
        TransactionBuilder { operations: Vec::new() }
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
