use crate::core::document::position::Position;
use crate::core::{NodeAttributes, TextDelta};
use indextree::NodeId;

pub enum DocumentOperation {
    Insert(InsertOperation),
    Update(UpdateOperation),
    Delete(DeleteOperation),
    TextEdit(TextEditOperation),
}

impl DocumentOperation {
    pub fn invert(&self) -> DocumentOperation {
        match self {
            DocumentOperation::Insert(insert_operation) => DocumentOperation::Delete(DeleteOperation {
                path: insert_operation.path.clone(),
                nodes: insert_operation.nodes.clone(),
            }),
            DocumentOperation::Update(update_operation) => DocumentOperation::Update(UpdateOperation {
                path: update_operation.path.clone(),
                attributes: update_operation.old_attributes.clone(),
                old_attributes: update_operation.attributes.clone(),
            }),
            DocumentOperation::Delete(delete_operation) => DocumentOperation::Insert(InsertOperation {
                path: delete_operation.path.clone(),
                nodes: delete_operation.nodes.clone(),
            }),
            DocumentOperation::TextEdit(text_edit_operation) => DocumentOperation::TextEdit(TextEditOperation {
                path: text_edit_operation.path.clone(),
                delta: text_edit_operation.inverted.clone(),
                inverted: text_edit_operation.delta.clone(),
            }),
        }
    }
}

pub struct InsertOperation {
    path: Position,
    nodes: Vec<NodeId>,
}

pub struct UpdateOperation {
    path: Position,
    attributes: NodeAttributes,
    old_attributes: NodeAttributes,
}

pub struct DeleteOperation {
    path: Position,
    nodes: Vec<NodeId>,
}

pub struct TextEditOperation {
    path: Position,
    delta: TextDelta,
    inverted: TextDelta,
}
