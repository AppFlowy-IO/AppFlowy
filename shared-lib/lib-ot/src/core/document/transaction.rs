use crate::core::document::position::Position;
use crate::core::{DeleteOperation, DocumentOperation, DocumentTree, InsertOperation, NodeData};

pub struct Transaction {
    pub operations: Vec<DocumentOperation>,
}

impl Transaction {
    fn new(operations: Vec<DocumentOperation>) -> Transaction {
        Transaction { operations }
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
            operations: Vec::new(),
        }
    }

    pub fn insert_nodes(&mut self, path: &Position, nodes: &[NodeData]) {
        self.push(DocumentOperation::Insert(InsertOperation {
            path: path.clone(),
            nodes: nodes.to_vec(),
        }));
    }

    pub fn delete_node(&mut self, path: &Position) {
        self.delete_nodes(path, 1);
    }

    pub fn delete_nodes(&mut self, path: &Position, length: usize) {
        let mut node = self.document.node_at_path(path).unwrap();
        let mut deleted_nodes: Vec<NodeData> = Vec::new();

        for _ in 0..length {
            let data = self.document.arena.get(node).unwrap();
            deleted_nodes.push(data.get().clone());
            node = node.following_siblings(&self.document.arena).next().unwrap();
        }

        self.operations.push(DocumentOperation::Delete(DeleteOperation {
            path: path.clone(),
            nodes: deleted_nodes,
        }))
    }

    pub fn push(&mut self, op: DocumentOperation) {
        self.operations.push(op);
    }

    pub fn finalize(self) -> Transaction {
        Transaction::new(self.operations)
    }
}
