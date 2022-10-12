use crate::core::attributes::AttributeHashMap;
use crate::core::{NodeData, NodeOperation, NodeTree, Path};
use crate::errors::OTError;
use indextree::NodeId;
use std::rc::Rc;

use super::{NodeBodyChangeset, NodeOperations};

#[derive(Debug, Clone, Default)]
pub struct Transaction {
    operations: NodeOperations,
}

impl Transaction {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_operations<T: Into<NodeOperations>>(operations: T) -> Self {
        Self {
            operations: operations.into(),
        }
    }

    pub fn into_operations(self) -> Vec<Rc<NodeOperation>> {
        self.operations.into_inner()
    }

    /// Make the `other` can be applied to the version after applying the `self` transaction.
    ///
    /// The semantics of transform is used when editing conflicts occur, which is often determined by the version id。
    /// the operations of the transaction will be transformed into the conflict operations.
    pub fn transform(&self, other: &Transaction) -> Result<Transaction, OTError> {
        let mut new_transaction = other.clone();
        for other_operation in new_transaction.iter_mut() {
            let other_operation = Rc::make_mut(other_operation);
            for operation in self.operations.iter() {
                operation.transform(other_operation);
            }
        }
        Ok(new_transaction)
    }

    pub fn compose(&mut self, other: &Transaction) -> Result<(), OTError> {
        // For the moment, just append `other` operations to the end of `self`.
        for operation in other.operations.iter() {
            self.operations.push(operation.clone());
        }
        Ok(())
    }
}

impl std::ops::Deref for Transaction {
    type Target = Vec<Rc<NodeOperation>>;

    fn deref(&self) -> &Self::Target {
        &self.operations
    }
}

impl std::ops::DerefMut for Transaction {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.operations
    }
}

pub struct TransactionBuilder<'a> {
    node_tree: &'a NodeTree,
    operations: NodeOperations,
}

impl<'a> TransactionBuilder<'a> {
    pub fn new(node_tree: &'a NodeTree) -> TransactionBuilder {
        TransactionBuilder {
            node_tree,
            operations: NodeOperations::default(),
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
    /// let mut node_tree = NodeTree::new("root");
    /// let transaction = TransactionBuilder::new(&node_tree)
    ///     .insert_nodes_at_path(0,vec![ NodeData::new("text_1"),  NodeData::new("text_2")])
    ///     .finalize();
    ///  node_tree.apply_transaction(transaction).unwrap();
    ///
    ///  node_tree.node_id_at_path(vec![0, 0]);
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
    /// let mut node_tree = NodeTree::new("root");
    /// let transaction = TransactionBuilder::new(&node_tree)
    ///     .insert_node_at_path(0, NodeData::new("text"))
    ///     .finalize();
    ///  node_tree.apply_transaction(transaction).unwrap();
    /// ```
    ///
    pub fn insert_node_at_path<T: Into<Path>>(self, path: T, node: NodeData) -> Self {
        self.insert_nodes_at_path(path, vec![node])
    }

    pub fn update_attributes_at_path(mut self, path: &Path, attributes: AttributeHashMap) -> Self {
        match self.node_tree.get_node_at_path(path) {
            Some(node) => {
                let mut old_attributes = AttributeHashMap::new();
                for key in attributes.keys() {
                    let old_attrs = &node.attributes;
                    if let Some(value) = old_attrs.get(key.as_str()) {
                        old_attributes.insert(key.clone(), value.clone());
                    }
                }

                self.operations.add_op(NodeOperation::UpdateAttributes {
                    path: path.clone(),
                    new: attributes,
                    old: old_attributes,
                });
            }
            None => tracing::warn!("Update attributes at path: {:?} failed. Node is not exist", path),
        }
        self
    }

    pub fn update_body_at_path(mut self, path: &Path, changeset: NodeBodyChangeset) -> Self {
        match self.node_tree.node_id_at_path(path) {
            Some(_) => {
                self.operations.add_op(NodeOperation::UpdateBody {
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

        self.operations.add_op(NodeOperation::Delete {
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
        self.operations.add_op(op);
        self
    }

    pub fn finalize(self) -> Transaction {
        Transaction::from_operations(self.operations)
    }
}
