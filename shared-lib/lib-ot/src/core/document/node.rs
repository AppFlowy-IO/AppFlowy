use crate::core::{NodeAttributes, TextDelta};

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct NodeData {
    pub node_type: String,
    pub attributes: NodeAttributes,
    pub delta: Option<TextDelta>,
}

impl NodeData {
    pub fn new(node_type: &str) -> NodeData {
        NodeData {
            node_type: node_type.into(),
            attributes: NodeAttributes::new(),
            delta: None,
        }
    }
}
