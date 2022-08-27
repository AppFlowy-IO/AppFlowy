use crate::core::document::position::Position;
use crate::core::{DocumentOperation, DocumentTree, NodeAttributes, NodeSubTree};
use indextree::NodeId;
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

    pub fn insert_nodes_at_path(&mut self, path: &Position, nodes: &[Box<NodeSubTree>]) {
        self.push(DocumentOperation::Insert {
            path: path.clone(),
            nodes: nodes.to_vec(),
        });
    }

    pub fn update_attributes_at_path(&mut self, path: &Position, attributes: HashMap<String, Option<String>>) {
        let mut old_attributes: HashMap<String, Option<String>> = HashMap::new();
        let node = self.document.node_at_path(path).unwrap();
        let node_data = self.document.arena.get(node).unwrap().get();

        for key in attributes.keys() {
            let old_attrs = &node_data.attributes;
            let old_value = match old_attrs.0.get(key.as_str()) {
                Some(value) => value.clone(),
                None => None,
            };
            old_attributes.insert(key.clone(), old_value);
        }

        self.push(DocumentOperation::Update {
            path: path.clone(),
            attributes: NodeAttributes(attributes),
            old_attributes: NodeAttributes(old_attributes),
        })
    }

    pub fn delete_node_at_path(&mut self, path: &Position) {
        self.delete_nodes_at_path(path, 1);
    }

    pub fn delete_nodes_at_path(&mut self, path: &Position, length: usize) {
        let mut node = self.document.node_at_path(path).unwrap();
        let mut deleted_nodes: Vec<Box<NodeSubTree>> = Vec::new();

        for _ in 0..length {
            deleted_nodes.push(self.get_deleted_nodes(node.clone()));
            node = node.following_siblings(&self.document.arena).next().unwrap();
        }

        self.operations.push(DocumentOperation::Delete {
            path: path.clone(),
            nodes: deleted_nodes,
        })
    }

    fn get_deleted_nodes(&self, node_id: NodeId) -> Box<NodeSubTree> {
        let node = self.document.arena.get(node_id.clone()).unwrap();
        let node_data = node.get();
        let mut children: Vec<Box<NodeSubTree>> = vec![];

        let mut children_iterators = node_id.children(&self.document.arena);
        loop {
            let next_child = children_iterators.next();
            if let Some(child_id) = next_child {
                children.push(self.get_deleted_nodes(child_id));
            } else {
                break;
            }
        }

        Box::new(NodeSubTree {
            node_type: node_data.node_type.clone(),
            attributes: node_data.attributes.clone(),
            delta: node_data.delta.clone(),
            children,
        })
    }

    pub fn push(&mut self, op: DocumentOperation) {
        self.operations.push(op);
    }

    pub fn finalize(self) -> Transaction {
        Transaction::new(self.operations)
    }
}
