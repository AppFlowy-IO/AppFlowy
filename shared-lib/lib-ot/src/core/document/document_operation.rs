use crate::core::document::position::Position;
use crate::core::{NodeAttributes, NodeData, TextDelta};

#[derive(Clone)]
pub enum DocumentOperation {
    Insert {
        path: Position,
        nodes: Vec<NodeData>,
    },
    Update {
        path: Position,
        attributes: NodeAttributes,
        old_attributes: NodeAttributes,
    },
    Delete {
        path: Position,
        nodes: Vec<NodeData>,
    },
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
