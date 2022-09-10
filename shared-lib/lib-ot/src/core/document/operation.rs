use crate::core::document::operation_serde::*;
use crate::core::document::path::Path;
use crate::core::{Node, NodeAttributes, NodeBodyChangeset};

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(tag = "op")]
pub enum NodeOperation {
    #[serde(rename = "insert")]
    Insert { path: Path, nodes: Vec<Node> },

    #[serde(rename = "update")]
    UpdateAttributes {
        path: Path,
        attributes: NodeAttributes,
        #[serde(rename = "oldAttributes")]
        old_attributes: NodeAttributes,
    },

    #[serde(rename = "edit-body")]
    #[serde(serialize_with = "serialize_edit_body")]
    // #[serde(deserialize_with = "operation_serde::deserialize_edit_body")]
    UpdateBody { path: Path, changeset: NodeBodyChangeset },

    #[serde(rename = "delete")]
    Delete { path: Path, nodes: Vec<Node> },
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

#[cfg(test)]
mod tests {
    use crate::core::{Node, NodeAttributes, NodeBodyChangeset, NodeBuilder, NodeOperation, Path, TextDelta};
    #[test]
    fn test_serialize_insert_operation() {
        let insert = NodeOperation::Insert {
            path: Path(vec![0, 1]),
            nodes: vec![Node::new("text".to_owned())],
        };
        let result = serde_json::to_string(&insert).unwrap();
        assert_eq!(result, r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text"}]}"#);
    }

    #[test]
    fn test_serialize_insert_sub_trees() {
        let insert = NodeOperation::Insert {
            path: Path(vec![0, 1]),
            nodes: vec![NodeBuilder::new("text").add_node(Node::new("text".to_owned())).build()],
        };
        let result = serde_json::to_string(&insert).unwrap();
        assert_eq!(
            result,
            r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text","children":[{"type":"text"}]}]}"#
        );
    }

    #[test]
    fn test_serialize_update_operation() {
        let insert = NodeOperation::UpdateAttributes {
            path: Path(vec![0, 1]),
            attributes: NodeAttributes::new(),
            old_attributes: NodeAttributes::new(),
        };
        let result = serde_json::to_string(&insert).unwrap();
        assert_eq!(
            result,
            r#"{"op":"update","path":[0,1],"attributes":{},"oldAttributes":{}}"#
        );
    }

    #[test]
    fn test_serialize_text_edit_operation() {
        let changeset = NodeBodyChangeset::Delta {
            delta: TextDelta::new(),
            inverted: TextDelta::new(),
        };
        let insert = NodeOperation::UpdateBody {
            path: Path(vec![0, 1]),
            changeset,
        };
        let result = serde_json::to_string(&insert).unwrap();
        assert_eq!(result, r#"{"op":"edit-body","path":[0,1],"delta":[],"inverted":[]}"#);
    }
}
