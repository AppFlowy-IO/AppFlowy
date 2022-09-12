use crate::core::document::path::Path;
use crate::core::{NodeAttributes, NodeBodyChangeset, NodeData};
use crate::errors::OTError;
use serde::{Deserialize, Serialize};

#[derive(Clone, Serialize, Deserialize)]
#[serde(tag = "op")]
pub enum NodeOperation {
    #[serde(rename = "insert")]
    Insert { path: Path, nodes: Vec<NodeData> },

    #[serde(rename = "update")]
    UpdateAttributes {
        path: Path,
        attributes: NodeAttributes,
        #[serde(rename = "oldAttributes")]
        old_attributes: NodeAttributes,
    },

    #[serde(rename = "update-body")]
    // #[serde(serialize_with = "serialize_edit_body")]
    // #[serde(deserialize_with = "deserialize_edit_body")]
    UpdateBody { path: Path, changeset: NodeBodyChangeset },

    #[serde(rename = "delete")]
    Delete { path: Path, nodes: Vec<NodeData> },
}

impl NodeOperation {
    pub fn path(&self) -> &Path {
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
    pub fn clone_with_new_path(&self, path: Path) -> NodeOperation {
        match self {
            NodeOperation::Insert { nodes, .. } => NodeOperation::Insert {
                path,
                nodes: nodes.clone(),
            },
            NodeOperation::UpdateAttributes {
                attributes,
                old_attributes,
                ..
            } => NodeOperation::UpdateAttributes {
                path,
                attributes: attributes.clone(),
                old_attributes: old_attributes.clone(),
            },
            NodeOperation::Delete { nodes, .. } => NodeOperation::Delete {
                path,
                nodes: nodes.clone(),
            },
            NodeOperation::UpdateBody { path, changeset } => NodeOperation::UpdateBody {
                path: path.clone(),
                changeset: changeset.clone(),
            },
        }
    }
    pub fn transform(a: &NodeOperation, b: &NodeOperation) -> NodeOperation {
        match a {
            NodeOperation::Insert { path: a_path, nodes } => {
                let new_path = Path::transform(a_path, b.path(), nodes.len() as i64);
                b.clone_with_new_path(new_path)
            }
            NodeOperation::Delete { path: a_path, nodes } => {
                let new_path = Path::transform(a_path, b.path(), nodes.len() as i64);
                b.clone_with_new_path(new_path)
            }
            _ => b.clone(),
        }
    }
}

#[derive(Serialize, Deserialize, Default)]
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
