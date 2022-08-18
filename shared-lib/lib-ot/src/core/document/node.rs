use std::cell::RefCell;
use crate::core::{TextDelta, NodeAttributes};

pub struct NodeData {
    pub node_type: String,
    pub attributes: RefCell<NodeAttributes>,
    pub delta: RefCell<Option<TextDelta>>,
}

impl NodeData {
    pub fn new(node_type: &str) -> NodeData {
        NodeData {
            node_type: node_type.into(),
            attributes: RefCell::new(NodeAttributes::new()),
            delta: RefCell::new(None),
        }
    }
}
