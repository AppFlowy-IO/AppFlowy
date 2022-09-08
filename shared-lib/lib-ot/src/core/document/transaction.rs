use crate::core::document::position::Path;
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


    ///
    ///
    /// # Arguments
    ///
    /// * `path`: the path that is used to save the nodes
    /// * `nodes`: the nodes you will be save in the path
    ///
    /// # Examples
    ///
    /// ```
    /// // -- 0 (root)
    /// //      0 -- text_1
    /// //      1 -- text_2
    /// use lib_ot::core::{DocumentTree, NodeSubTree, TransactionBuilder};
    /// let mut document = DocumentTree::new();
    /// let transaction = {
    ///     let mut tb = TransactionBuilder::new(&document);
    ///     tb.insert_nodes_at_path(0,vec![ NodeSubTree::new("text_1"),  NodeSubTree::new("text_2")]);
    ///     tb.finalize()
    /// };
    ///  document.apply(transaction).unwrap();
    ///
    ///  document.node_at_path(vec![0, 0]);
    /// ```
    ///
    pub fn insert_nodes_at_path<T: Into<Path>>(&mut self, path: T, nodes: Vec<NodeSubTree>) {
        self.push(DocumentOperation::Insert {
            path: path.into(),
            nodes,
        });
    }

    ///
    ///
    /// # Arguments
    ///
    /// * `path`: the path that is used to save the nodes
    /// * `node`: the node data will be saved in the path
    ///
    /// # Examples
    ///
    /// ```
    /// // 0
    /// // -- 0
    /// //    |-- text
    /// use lib_ot::core::{DocumentTree, NodeSubTree, TransactionBuilder};
    /// let mut document = DocumentTree::new();
    /// let transaction = {
    ///     let mut tb = TransactionBuilder::new(&document);
    ///     tb.insert_node_at_path(0, NodeSubTree::new("text"));
    ///     tb.finalize()
    /// };
    ///  document.apply(transaction).unwrap();
    /// ```
    ///
    pub fn insert_node_at_path<T: Into<Path>>(&mut self, path: T, node: NodeSubTree) {
       self.insert_nodes_at_path(path, vec![node]);
    }

    pub fn update_attributes_at_path(&mut self, path: &Path, attributes: HashMap<String, Option<String>>) {
        let mut old_attributes: HashMap<String, Option<String>> = HashMap::new();
        let node = self.document.node_at_path(path).unwrap();
        let node_data = self.document.get_node_data(node).unwrap();

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

    pub fn delete_node_at_path(&mut self, path: &Path) {
        self.delete_nodes_at_path(path, 1);
    }

    pub fn delete_nodes_at_path(&mut self, path: &Path, length: usize) {
        let mut node = self.document.node_at_path(path).unwrap();
        let mut deleted_nodes  = vec![];
        for _ in 0..length {
            deleted_nodes.push(self.get_deleted_nodes(node));
            node =  self.document.following_siblings(node).next().unwrap();
        }

        self.operations.push(DocumentOperation::Delete {
            path: path.clone(),
            nodes: deleted_nodes,
        })
    }

    fn get_deleted_nodes(&self, node_id: NodeId) -> NodeSubTree {
        let node_data = self.document.get_node_data(node_id).unwrap();

        let mut children  = vec![];
        self.document.children_from_node(node_id).for_each(|child_id| {
            children.push(self.get_deleted_nodes(child_id));
        });

        NodeSubTree {
            node_type: node_data.node_type.clone(),
            attributes: node_data.attributes.clone(),
            delta: node_data.delta.clone(),
            children,
        }
    }

    pub fn push(&mut self, op: DocumentOperation) {
        self.operations.push(op);
    }

    pub fn finalize(self) -> Transaction {
        Transaction::new(self.operations)
    }
}
