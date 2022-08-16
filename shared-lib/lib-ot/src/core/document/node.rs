use crate::core::NodeAttributes;

pub struct NodeData {
    pub node_type: String,
    pub attributes: NodeAttributes,
}

impl NodeData {
    pub fn new(node_type: &str) -> NodeData {
        NodeData {
            node_type: node_type.into(),
            attributes: NodeAttributes::new(),
        }
    }
}
