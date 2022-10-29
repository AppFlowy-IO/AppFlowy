use crate::core::{Body, Changeset, NodeData, OperationTransform, Path};
use crate::errors::OTError;

use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum NodeOperation {
    #[serde(rename = "insert")]
    Insert { path: Path, nodes: Vec<NodeData> },

    #[serde(rename = "update")]
    Update { path: Path, changeset: Changeset },

    #[serde(rename = "delete")]
    Delete { path: Path, nodes: Vec<NodeData> },
}

impl NodeOperation {
    pub fn get_path(&self) -> &Path {
        match self {
            NodeOperation::Insert { path, .. } => path,
            NodeOperation::Delete { path, .. } => path,
            NodeOperation::Update { path, .. } => path,
        }
    }

    pub fn get_mut_path(&mut self) -> &mut Path {
        match self {
            NodeOperation::Insert { path, .. } => path,
            NodeOperation::Delete { path, .. } => path,
            NodeOperation::Update { path, .. } => path,
        }
    }

    pub fn is_update_delta(&self) -> bool {
        match self {
            NodeOperation::Insert { .. } => false,
            NodeOperation::Update { path: _, changeset } => changeset.is_delta(),
            NodeOperation::Delete { .. } => false,
        }
    }

    pub fn is_update_attribute(&self) -> bool {
        match self {
            NodeOperation::Insert { .. } => false,
            NodeOperation::Update { path: _, changeset } => changeset.is_attribute(),
            NodeOperation::Delete { .. } => false,
        }
    }
    pub fn is_insert(&self) -> bool {
        match self {
            NodeOperation::Insert { .. } => true,
            NodeOperation::Update { .. } => false,
            NodeOperation::Delete { .. } => false,
        }
    }
    pub fn can_compose(&self, other: &NodeOperation) -> bool {
        if self.get_path() != other.get_path() {
            return false;
        }
        if self.is_update_delta() && other.is_update_delta() {
            return true;
        }

        if self.is_update_attribute() && other.is_update_attribute() {
            return true;
        }

        if self.is_insert() && other.is_update_delta() {
            return true;
        }
        false
    }

    pub fn compose(&mut self, other: &NodeOperation) -> Result<(), OTError> {
        match (self, other) {
            (
                NodeOperation::Insert { path: _, nodes },
                NodeOperation::Update {
                    path: _other_path,
                    changeset,
                },
            ) => {
                match changeset {
                    Changeset::Delta { delta, inverted: _ } => {
                        if let Body::Delta(old_delta) = &mut nodes.last_mut().unwrap().body {
                            let new_delta = old_delta.compose(delta)?;
                            *old_delta = new_delta;
                        }
                    }
                    Changeset::Attributes { new: _, old: _ } => {
                        return Err(OTError::compose().context("Can't compose the attributes changeset"));
                    }
                }
                Ok(())
            }
            (
                NodeOperation::Update { path: _, changeset },
                NodeOperation::Update {
                    path: _,
                    changeset: other_changeset,
                },
            ) => changeset.compose(other_changeset),
            (_left, _right) => Err(OTError::compose().context("Can't compose the operation")),
        }
    }

    pub fn inverted(&self) -> NodeOperation {
        match self {
            NodeOperation::Insert { path, nodes } => NodeOperation::Delete {
                path: path.clone(),
                nodes: nodes.clone(),
            },
            NodeOperation::Delete { path, nodes } => NodeOperation::Insert {
                path: path.clone(),
                nodes: nodes.clone(),
            },
            NodeOperation::Update { path, changeset: body } => NodeOperation::Update {
                path: path.clone(),
                changeset: body.inverted(),
            },
        }
    }

    /// Make the `other` operation can be applied to the version after applying the `self` operation.
    /// The semantics of transform is used when editing conflicts occur, which is often determined by the version id。
    /// For example, if the inserted position has been acquired by others, then it's needed to do the transform to
    /// make sure the inserted position is right.
    ///
    /// # Arguments
    ///
    /// * `other`: The operation that is going to be transformed
    ///
    /// # Examples
    ///
    /// ```
    /// use lib_ot::core::{NodeDataBuilder, NodeOperation, Path};
    /// let node_1 = NodeDataBuilder::new("text_1").build();
    /// let node_2 = NodeDataBuilder::new("text_2").build();
    ///
    /// let op_1 = NodeOperation::Insert {
    ///     path: Path(vec![0, 1]),
    ///     nodes: vec![node_1],
    /// };
    ///
    /// let mut op_2 = NodeOperation::Insert {
    ///     path: Path(vec![0, 1]),
    ///     nodes: vec![node_2],
    /// };
    ///
    /// assert_eq!(serde_json::to_string(&op_2).unwrap(), r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text_2"}]}"#);
    ///
    /// op_1.transform(&mut op_2);
    /// assert_eq!(serde_json::to_string(&op_2).unwrap(), r#"{"op":"insert","path":[0,2],"nodes":[{"type":"text_2"}]}"#);
    /// assert_eq!(serde_json::to_string(&op_1).unwrap(), r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text_1"}]}"#);
    /// ```
    pub fn transform(&self, other: &mut NodeOperation) {
        match self {
            NodeOperation::Insert { path, nodes } => {
                let new_path = path.transform(other.get_path(), nodes.len());
                *other.get_mut_path() = new_path;
            }
            NodeOperation::Delete { path, nodes } => {
                let new_path = path.transform(other.get_path(), nodes.len());
                *other.get_mut_path() = new_path;
            }
            _ => {
                // Only insert/delete will change the path.
            }
        }
    }
}

type OperationIndexMap = Vec<Arc<NodeOperation>>;

#[derive(Debug, Clone, Default)]
pub struct NodeOperations {
    inner: OperationIndexMap,
}

impl NodeOperations {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn from_operations(operations: Vec<NodeOperation>) -> Self {
        let mut ops = Self::new();
        for op in operations {
            ops.push_op(op)
        }
        ops
    }

    pub fn from_bytes(bytes: Vec<u8>) -> Result<Self, OTError> {
        let operation_list = serde_json::from_slice(&bytes).map_err(|err| OTError::serde().context(err))?;
        Ok(operation_list)
    }

    pub fn to_bytes(&self) -> Result<Vec<u8>, OTError> {
        let bytes = serde_json::to_vec(self).map_err(|err| OTError::serde().context(err))?;
        Ok(bytes)
    }

    pub fn values(&self) -> &Vec<Arc<NodeOperation>> {
        &self.inner
    }

    pub fn values_mut(&mut self) -> &mut Vec<Arc<NodeOperation>> {
        &mut self.inner
    }

    pub fn len(&self) -> usize {
        self.values().len()
    }

    pub fn is_empty(&self) -> bool {
        self.inner.is_empty()
    }

    pub fn into_inner(self) -> Vec<Arc<NodeOperation>> {
        self.inner
    }

    pub fn push_op<T: Into<Arc<NodeOperation>>>(&mut self, other: T) {
        let other = other.into();
        if let Some(last_operation) = self.inner.last_mut() {
            if last_operation.can_compose(&other) {
                let mut_operation = Arc::make_mut(last_operation);
                if mut_operation.compose(&other).is_ok() {
                    return;
                }
            }
        }

        // if let Some(operations) = self.inner.get_mut(other.get_path()) {
        //     if let Some(last_operation) = operations.last_mut() {
        //         if last_operation.can_compose(&other) {
        //             let mut_operation = Arc::make_mut(last_operation);
        //             if mut_operation.compose(&other).is_ok() {
        //                 return;
        //             }
        //         }
        //     }
        // }
        // If the passed-in operation can't be composed, then append it to the end.
        self.inner.push(other);
    }

    pub fn compose(&mut self, other: NodeOperations) {
        for operation in other.values() {
            self.push_op(operation.clone());
        }
    }

    pub fn inverted(&self) -> Self {
        let mut operations = Self::new();
        for operation in self.values() {
            operations.push_op(operation.inverted());
        }
        operations
    }
}

impl std::convert::From<Vec<NodeOperation>> for NodeOperations {
    fn from(operations: Vec<NodeOperation>) -> Self {
        Self::from_operations(operations)
    }
}
