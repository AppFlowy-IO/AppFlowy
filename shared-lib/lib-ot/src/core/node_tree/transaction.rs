use super::{Changeset, NodeOperations};
use crate::core::{NodeData, NodeOperation, NodeTree, Path};
use crate::errors::OTError;
use indextree::NodeId;
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct Transaction {
    pub operations: NodeOperations,

    #[serde(default)]
    #[serde(skip_serializing_if = "Extension::is_empty")]
    pub extension: Extension,
}

impl Transaction {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_operations<T: Into<NodeOperations>>(operations: T) -> Self {
        Self {
            operations: operations.into(),
            extension: Extension::Empty,
        }
    }

    pub fn from_bytes(bytes: &[u8]) -> Result<Self, OTError> {
        let transaction = serde_json::from_slice(bytes).map_err(|err| OTError::serde().context(err))?;
        Ok(transaction)
    }

    pub fn to_bytes(&self) -> Result<Vec<u8>, OTError> {
        let bytes = serde_json::to_vec(&self).map_err(|err| OTError::serde().context(err))?;
        Ok(bytes)
    }

    pub fn from_json(s: &str) -> Result<Self, OTError> {
        let serde_transaction: Transaction = serde_json::from_str(s).map_err(|err| OTError::serde().context(err))?;
        let mut transaction = Self::new();
        transaction.extension = serde_transaction.extension;
        for operation in serde_transaction.operations.into_inner() {
            transaction.operations.push_op(operation);
        }
        Ok(transaction)
    }

    pub fn to_json(&self) -> Result<String, OTError> {
        serde_json::to_string(&self).map_err(|err| OTError::serde().context(err))
    }

    pub fn into_operations(self) -> Vec<Arc<NodeOperation>> {
        self.operations.into_inner()
    }

    pub fn split(self) -> (Vec<Arc<NodeOperation>>, Extension) {
        (self.operations.into_inner(), self.extension)
    }

    pub fn push_operation<T: Into<NodeOperation>>(&mut self, operation: T) {
        let operation = operation.into();
        self.operations.push_op(operation);
    }

    /// Make the `other` can be applied to the version after applying the `self` transaction.
    ///
    /// The semantics of transform is used when editing conflicts occur, which is often determined by the version id。
    /// the operations of the transaction will be transformed into the conflict operations.
    pub fn transform(&self, other: &Transaction) -> Result<Transaction, OTError> {
        let mut other = other.clone();
        other.extension = self.extension.clone();

        for other_operation in other.operations.values_mut() {
            let other_operation = Arc::make_mut(other_operation);
            for operation in self.operations.values() {
                operation.transform(other_operation);
            }
        }

        Ok(other)
    }

    pub fn compose(&mut self, other: Transaction) -> Result<(), OTError> {
        // For the moment, just append `other` operations to the end of `self`.
        let Transaction { operations, extension } = other;
        self.operations.compose(operations);
        self.extension = extension;
        Ok(())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum Extension {
    Empty,
    TextSelection {
        before_selection: Selection,
        after_selection: Selection,
    },
}

impl std::default::Default for Extension {
    fn default() -> Self {
        Extension::Empty
    }
}

impl Extension {
    fn is_empty(&self) -> bool {
        matches!(self, Extension::Empty)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Selection {
    start: Position,
    end: Position,
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Position {
    path: Path,
    offset: usize,
}
#[derive(Default)]
pub struct TransactionBuilder {
    operations: NodeOperations,
}

impl TransactionBuilder {
    pub fn new() -> TransactionBuilder {
        Self::default()
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
    /// //   0 -- text_1
    /// use lib_ot::core::{NodeTree, NodeData, TransactionBuilder};
    /// let mut node_tree = NodeTree::default();
    /// let transaction = TransactionBuilder::new()
    ///     .insert_nodes_at_path(0,vec![ NodeData::new("text_1")])
    ///     .build();
    ///  node_tree.apply_transaction(transaction).unwrap();
    ///
    ///  node_tree.node_id_at_path(vec![0]).unwrap();
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
    /// let mut node_tree = NodeTree::default();
    /// let transaction = TransactionBuilder::new()
    ///     .insert_node_at_path(0, NodeData::new("text"))
    ///     .build();
    ///  node_tree.apply_transaction(transaction).unwrap();
    /// ```
    ///
    pub fn insert_node_at_path<T: Into<Path>>(self, path: T, node: NodeData) -> Self {
        self.insert_nodes_at_path(path, vec![node])
    }

    pub fn update_node_at_path<T: Into<Path>>(mut self, path: T, changeset: Changeset) -> Self {
        self.operations.push_op(NodeOperation::Update {
            path: path.into(),
            changeset,
        });
        self
    }
    //
    // pub fn update_delta_at_path<T: Into<Path>>(
    //     mut self,
    //     path: T,
    //     new_delta: DeltaTextOperations,
    // ) -> Result<Self, OTError> {
    //     let path = path.into();
    //     let operation: NodeOperation = self
    //         .operations
    //         .get(&path)
    //         .ok_or(Err(OTError::record_not_found().context("Can't found the node")))?;
    //
    //     match operation {
    //         NodeOperation::Insert { path, nodes } => {}
    //         NodeOperation::Update { path, changeset } => {}
    //         NodeOperation::Delete { .. } => {}
    //     }
    //
    //     match node.body {
    //         Body::Empty => Ok(self),
    //         Body::Delta(delta) => {
    //             let inverted = new_delta.invert(&delta);
    //             let changeset = Changeset::Delta {
    //                 delta: new_delta,
    //                 inverted,
    //             };
    //             Ok(self.update_node_at_path(path, changeset))
    //         }
    //     }
    // }

    pub fn delete_node_at_path(self, node_tree: &NodeTree, path: &Path) -> Self {
        self.delete_nodes_at_path(node_tree, path, 1)
    }

    pub fn delete_nodes_at_path(mut self, node_tree: &NodeTree, path: &Path, length: usize) -> Self {
        let node_id = node_tree.node_id_at_path(path);
        if node_id.is_none() {
            tracing::warn!("Path: {:?} doesn't contains any nodes", path);
            return self;
        }

        let mut node_id = node_id.unwrap();
        let mut deleted_nodes = vec![];
        for _ in 0..length {
            deleted_nodes.push(self.get_deleted_node_data(node_tree, node_id));
            node_id = node_tree.following_siblings(node_id).next().unwrap();
        }

        self.operations.push_op(NodeOperation::Delete {
            path: path.clone(),
            nodes: deleted_nodes,
        });
        self
    }

    fn get_deleted_node_data(&self, node_tree: &NodeTree, node_id: NodeId) -> NodeData {
        recursive_get_deleted_node_data(node_tree, node_id)
    }

    pub fn push(mut self, op: NodeOperation) -> Self {
        self.operations.push_op(op);
        self
    }

    pub fn build(self) -> Transaction {
        Transaction::from_operations(self.operations)
    }
}

fn recursive_get_deleted_node_data(node_tree: &NodeTree, node_id: NodeId) -> NodeData {
    let node_data = node_tree.get_node(node_id).unwrap();
    let mut children = vec![];
    node_tree.get_children_ids(node_id).into_iter().for_each(|child_id| {
        let child = recursive_get_deleted_node_data(node_tree, child_id);
        children.push(child);
    });

    NodeData {
        node_type: node_data.node_type.clone(),
        attributes: node_data.attributes.clone(),
        body: node_data.body.clone(),
        children,
    }
}
