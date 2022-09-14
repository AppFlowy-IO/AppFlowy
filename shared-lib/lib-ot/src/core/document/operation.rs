use crate::core::attributes::Attributes;
use crate::core::document::path::Path;
use crate::core::{NodeBodyChangeset, NodeData, OperationTransform};
use crate::errors::OTError;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum NodeOperation {
    #[serde(rename = "insert")]
    Insert { path: Path, nodes: Vec<NodeData> },

    #[serde(rename = "update")]
    UpdateAttributes {
        path: Path,
        attributes: Attributes,
        #[serde(rename = "oldAttributes")]
        old_attributes: Attributes,
    },

    #[serde(rename = "update-body")]
    // #[serde(serialize_with = "serialize_edit_body")]
    // #[serde(deserialize_with = "deserialize_edit_body")]
    UpdateBody { path: Path, changeset: NodeBodyChangeset },

    #[serde(rename = "delete")]
    Delete { path: Path, nodes: Vec<NodeData> },
}

// impl OperationTransform for NodeOperation {
//     fn compose(&self, other: &Self) -> Result<Self, OTError>
//     where
//         Self: Sized,
//     {
//         match self {
//             NodeOperation::Insert { path, nodes } => {
//                 let new_path = Path::transform(path, other.path(), nodes.len() as i64);
//                 Ok((self.clone(), other.clone_with_new_path(new_path)))
//             }
//             NodeOperation::Delete { path, nodes } => {
//                 let new_path = Path::transform(path, other.path(), nodes.len() as i64);
//                 other.clone_with_new_path(new_path)
//             }
//             _ => other.clone(),
//         }
//     }
//
//     fn transform(&self, other: &Self) -> Result<(Self, Self), OTError>
//     where
//         Self: Sized,
//     {
//         todo!()
//     }
//
//     fn invert(&self, other: &Self) -> Self {
//         todo!()
//     }
// }
impl NodeOperation {
    pub fn get_path(&self) -> &Path {
        match self {
            NodeOperation::Insert { path, .. } => path,
            NodeOperation::UpdateAttributes { path, .. } => path,
            NodeOperation::Delete { path, .. } => path,
            NodeOperation::UpdateBody { path, .. } => path,
        }
    }

    pub fn get_mut_path(&mut self) -> &mut Path {
        match self {
            NodeOperation::Insert { path, .. } => path,
            NodeOperation::UpdateAttributes { path, .. } => path,
            NodeOperation::Delete { path, .. } => path,
            NodeOperation::UpdateBody { path, .. } => path,
        }
    }

    pub fn invert(&self) -> NodeOperation {
        match self {
            NodeOperation::Insert { path, nodes } => NodeOperation::Delete {
                path: path.clone(),
                nodes: nodes.clone(),
            },
            NodeOperation::UpdateAttributes {
                path,
                attributes,
                old_attributes,
            } => NodeOperation::UpdateAttributes {
                path: path.clone(),
                attributes: old_attributes.clone(),
                old_attributes: attributes.clone(),
            },
            NodeOperation::Delete { path, nodes } => NodeOperation::Insert {
                path: path.clone(),
                nodes: nodes.clone(),
            },
            NodeOperation::UpdateBody { path, changeset: body } => NodeOperation::UpdateBody {
                path: path.clone(),
                changeset: body.inverted(),
            },
        }
    }

    /// Make the `other` operation to be applied to the version that has been modified.
    /// The semantics of transform is used when editing conflicts occur, which is often determined by the version id。
    /// For example, if the inserted position has been acquired by others, then you need to do transform to make sure
    /// your position is value.
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
    ///
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
            _ => {}
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct NodeOperationList {
    operations: Vec<NodeOperation>,
}

impl NodeOperationList {
    pub fn into_inner(self) -> Vec<NodeOperation> {
        self.operations
    }
}

impl std::ops::Deref for NodeOperationList {
    type Target = Vec<NodeOperation>;

    fn deref(&self) -> &Self::Target {
        &self.operations
    }
}

impl std::ops::DerefMut for NodeOperationList {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.operations
    }
}

impl std::convert::From<Vec<NodeOperation>> for NodeOperationList {
    fn from(operations: Vec<NodeOperation>) -> Self {
        Self { operations }
    }
}

impl NodeOperationList {
    pub fn new(operations: Vec<NodeOperation>) -> Self {
        Self { operations }
    }

    pub fn from_bytes(bytes: Vec<u8>) -> Result<Self, OTError> {
        let operation_list = serde_json::from_slice(&bytes).map_err(|err| OTError::serde().context(err))?;
        Ok(operation_list)
    }

    pub fn to_bytes(&self) -> Result<Vec<u8>, OTError> {
        let bytes = serde_json::to_vec(self).map_err(|err| OTError::serde().context(err))?;
        Ok(bytes)
    }
}
