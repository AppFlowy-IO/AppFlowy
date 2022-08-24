use crate::core::document::position::Position;
use crate::core::{NodeAttributes, NodeSubTree, TextDelta};

#[derive(Clone, serde::Serialize, serde::Deserialize)]
#[serde(tag = "op")]
pub enum DocumentOperation {
    #[serde(rename = "insert")]
    Insert {
        path: Position,
        nodes: Vec<Box<NodeSubTree>>,
    },
    #[serde(rename = "update")]
    Update {
        path: Position,
        attributes: NodeAttributes,
        #[serde(rename = "oldAttributes")]
        old_attributes: NodeAttributes,
    },
    #[serde(rename = "delete")]
    Delete {
        path: Position,
        nodes: Vec<Box<NodeSubTree>>,
    },
    #[serde(rename = "text-edit")]
    TextEdit {
        path: Position,
        delta: TextDelta,
        inverted: TextDelta,
    },
}

impl DocumentOperation {
    pub fn path(&self) -> &Position {
        match self {
            DocumentOperation::Insert { path, .. } => path,
            DocumentOperation::Update { path, .. } => path,
            DocumentOperation::Delete { path, .. } => path,
            DocumentOperation::TextEdit { path, .. } => path,
        }
    }
    pub fn invert(&self) -> DocumentOperation {
        match self {
            DocumentOperation::Insert { path, nodes } => DocumentOperation::Delete {
                path: path.clone(),
                nodes: nodes.clone(),
            },
            DocumentOperation::Update {
                path,
                attributes,
                old_attributes,
            } => DocumentOperation::Update {
                path: path.clone(),
                attributes: old_attributes.clone(),
                old_attributes: attributes.clone(),
            },
            DocumentOperation::Delete { path, nodes } => DocumentOperation::Insert {
                path: path.clone(),
                nodes: nodes.clone(),
            },
            DocumentOperation::TextEdit { path, delta, inverted } => DocumentOperation::TextEdit {
                path: path.clone(),
                delta: inverted.clone(),
                inverted: delta.clone(),
            },
        }
    }
    pub fn clone_with_new_path(&self, path: Position) -> DocumentOperation {
        match self {
            DocumentOperation::Insert { nodes, .. } => DocumentOperation::Insert {
                path,
                nodes: nodes.clone(),
            },
            DocumentOperation::Update {
                attributes,
                old_attributes,
                ..
            } => DocumentOperation::Update {
                path,
                attributes: attributes.clone(),
                old_attributes: old_attributes.clone(),
            },
            DocumentOperation::Delete { nodes, .. } => DocumentOperation::Delete {
                path,
                nodes: nodes.clone(),
            },
            DocumentOperation::TextEdit { delta, inverted, .. } => DocumentOperation::TextEdit {
                path,
                delta: delta.clone(),
                inverted: inverted.clone(),
            },
        }
    }
    pub fn transform(a: &DocumentOperation, b: &DocumentOperation) -> DocumentOperation {
        match a {
            DocumentOperation::Insert { path: a_path, nodes } => {
                let new_path = Position::transform(a_path, b.path(), nodes.len() as i64);
                b.clone_with_new_path(new_path)
            }
            DocumentOperation::Delete { path: a_path, nodes } => {
                let new_path = Position::transform(a_path, b.path(), nodes.len() as i64);
                b.clone_with_new_path(new_path)
            }
            _ => b.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use crate::core::{Delta, DocumentOperation, NodeAttributes, NodeSubTree, Position};

    #[test]
    fn test_transform_path_1() {
        assert_eq!(
            { Position::transform(&Position(vec![0, 1]), &Position(vec![0, 1]), 1) }.0,
            vec![0, 2]
        );
    }

    #[test]
    fn test_transform_path_2() {
        assert_eq!(
            { Position::transform(&Position(vec![0, 1]), &Position(vec![0, 2]), 1) }.0,
            vec![0, 3]
        );
    }

    #[test]
    fn test_transform_path_3() {
        assert_eq!(
            { Position::transform(&Position(vec![0, 1]), &Position(vec![0, 2, 7, 8, 9]), 1) }.0,
            vec![0, 3, 7, 8, 9]
        );
    }

    #[test]
    fn test_transform_path_not_changed() {
        assert_eq!(
            { Position::transform(&Position(vec![0, 1, 2]), &Position(vec![0, 0, 7, 8, 9]), 1) }.0,
            vec![0, 0, 7, 8, 9]
        );
        assert_eq!(
            { Position::transform(&Position(vec![0, 1, 2]), &Position(vec![0, 1]), 1) }.0,
            vec![0, 1]
        );
        assert_eq!(
            { Position::transform(&Position(vec![1, 1]), &Position(vec![1, 0]), 1) }.0,
            vec![1, 0]
        );
    }

    #[test]
    fn test_transform_delta() {
        assert_eq!(
            { Position::transform(&Position(vec![0, 1]), &Position(vec![0, 1]), 5) }.0,
            vec![0, 6]
        );
    }

    #[test]
    fn test_serialize_insert_operation() {
        let insert = DocumentOperation::Insert {
            path: Position(vec![0, 1]),
            nodes: vec![Box::new(NodeSubTree::new("text"))],
        };
        let result = serde_json::to_string(&insert).unwrap();
        assert_eq!(
            result,
            r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text","attributes":{}}]}"#
        );
    }

    #[test]
    fn test_serialize_insert_sub_trees() {
        let insert = DocumentOperation::Insert {
            path: Position(vec![0, 1]),
            nodes: vec![Box::new(NodeSubTree {
                node_type: "text".into(),
                attributes: NodeAttributes::new(),
                delta: None,
                children: vec![Box::new(NodeSubTree::new("text".into()))],
            })],
        };
        let result = serde_json::to_string(&insert).unwrap();
        assert_eq!(
            result,
            r#"{"op":"insert","path":[0,1],"nodes":[{"type":"text","attributes":{},"children":[{"type":"text","attributes":{}}]}]}"#
        );
    }

    #[test]
    fn test_serialize_update_operation() {
        let insert = DocumentOperation::Update {
            path: Position(vec![0, 1]),
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
        let insert = DocumentOperation::TextEdit {
            path: Position(vec![0, 1]),
            delta: Delta::new(),
            inverted: Delta::new(),
        };
        let result = serde_json::to_string(&insert).unwrap();
        assert_eq!(result, r#"{"op":"text-edit","path":[0,1],"delta":[],"inverted":[]}"#);
    }
}
