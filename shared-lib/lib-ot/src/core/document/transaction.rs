use crate::core::document::path::Path;
use crate::core::{NodeAttributes, NodeData, NodeOperation, NodeTree};
use indextree::NodeId;

use super::{NodeBodyChangeset, NodeOperationList};

pub struct Transaction {
    pub operations: NodeOperationList,
}

impl Transaction {
    fn new(operations: NodeOperationList) -> Transaction {
        Transaction { operations }
    }
}

pub struct TransactionBuilder<'a> {
    node_tree: &'a NodeTree,
    operations: NodeOperationList,
}

impl<'a> TransactionBuilder<'a> {
    pub fn new(node_tree: &'a NodeTree) -> TransactionBuilder {
        TransactionBuilder {
            node_tree,
            operations: NodeOperationList::default(),
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
    /// use lib_ot::core::{NodeTree, NodeData, TransactionBuilder};
    /// let mut node_tree = NodeTree::new();
    /// let transaction = TransactionBuilder::new(&node_tree)
    ///     .insert_nodes_at_path(0,vec![ NodeData::new("text_1"),  NodeData::new("text_2")])
    ///     .finalize();
    ///  node_tree.apply(transaction).unwrap();
    ///
    ///  node_tree.node_at_path(vec![0, 0]);
    /// ```
    ///
    pub fn insert_nodes_at_path<T: Into<Path>>(self, path: T, nodes: Vec<NodeData>) -> Self {
        self.push(NodeOperation::Insert {
            path: path.into(),
            nodes,
        })
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
    /// use lib_ot::core::{NodeTree, NodeData, TransactionBuilder};
    /// let mut node_tree = NodeTree::new();
    /// let transaction = TransactionBuilder::new(&node_tree)
    ///     .insert_node_at_path(0, NodeData::new("text"))
    ///     .finalize();
    ///  node_tree.apply(transaction).unwrap();
    /// ```
    ///
    pub fn insert_node_at_path<T: Into<Path>>(self, path: T, node: NodeData) -> Self {
        self.insert_nodes_at_path(path, vec![node])
    }

    pub fn update_attributes_at_path(mut self, path: &Path, attributes: NodeAttributes) -> Self {
        match self.node_tree.get_node_at_path(path) {
            Some(node) => {
                let mut old_attributes = NodeAttributes::new();
                for key in attributes.keys() {
                    let old_attrs = &node.attributes;
                    if let Some(value) = old_attrs.get(key.as_str()) {
                        old_attributes.insert(key.clone(), value.clone());
                    }
                }

                self.operations.push(NodeOperation::UpdateAttributes {
                    path: path.clone(),
                    attributes,
                    old_attributes,
                });
            }
            None => tracing::warn!("Update attributes at path: {:?} failed. Node is not exist", path),
        }
        self
    }

    pub fn update_body_at_path(mut self, path: &Path, changeset: NodeBodyChangeset) -> Self {
        match self.node_tree.node_id_at_path(path) {
            Some(_) => {
                self.operations.push(NodeOperation::UpdateBody {
                    path: path.clone(),
                    changeset,
                });
            }
            None => tracing::warn!("Update attributes at path: {:?} failed. Node is not exist", path),
        }
        self
    }

    pub fn delete_node_at_path(self, path: &Path) -> Self {
        self.delete_nodes_at_path(path, 1)
    }

    pub fn delete_nodes_at_path(mut self, path: &Path, length: usize) -> Self {
        let mut node = self.node_tree.node_id_at_path(path).unwrap();
        let mut deleted_nodes = vec![];
        for _ in 0..length {
            deleted_nodes.push(self.get_deleted_nodes(node));
            node = self.node_tree.following_siblings(node).next().unwrap();
        }

        self.operations.push(NodeOperation::Delete {
            path: path.clone(),
            nodes: deleted_nodes,
        });
        self
    }

    fn get_deleted_nodes(&self, node_id: NodeId) -> NodeData {
        let node_data = self.node_tree.get_node(node_id).unwrap();

        let mut children = vec![];
        self.node_tree.children_from_node(node_id).for_each(|child_id| {
            children.push(self.get_deleted_nodes(child_id));
        });

        NodeData {
            node_type: node_data.node_type.clone(),
            attributes: node_data.attributes.clone(),
            body: node_data.body.clone(),
            children,
        }
    }

    pub fn push(mut self, op: NodeOperation) -> Self {
        self.operations.push(op);
        self
    }

    pub fn finalize(self) -> Transaction {
        Transaction::new(self.operations)
    }
}
