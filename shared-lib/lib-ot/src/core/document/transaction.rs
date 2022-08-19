use crate::core::document::position::Position;
use crate::core::{
    DeleteOperation, DocumentOperation, DocumentTree, InsertOperation, NodeAttributes, NodeData, UpdateOperation,
};
use std::collections::HashMap;

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

    pub fn update_attributes(&mut self, path: &Position, attributes: HashMap<String, Option<String>>) {
        let mut old_attributes: HashMap<String, Option<String>> = HashMap::new();
        let node = self.document.node_at_path(path).unwrap();
        let node_data = self.document.arena.get(node).unwrap().get();

        for key in attributes.keys() {
            let old_attrs = node_data.attributes.borrow();
            let old_value = match old_attrs.0.get(key.as_str()) {
                Some(value) => value.clone(),
                None => None,
            };
            old_attributes.insert(key.clone(), old_value);
        }

        self.push(DocumentOperation::Update(UpdateOperation {
            path: path.clone(),
            attributes: NodeAttributes(attributes),
            old_attributes: NodeAttributes(old_attributes),
        }))
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
