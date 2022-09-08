use crate::core::{NodeAttributes, TextDelta};

#[derive(Clone)]
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

#[derive(Clone, serde::Serialize, serde::Deserialize)]
pub struct NodeSubTree {
    #[serde(rename = "type")]
    pub note_type: String,

    pub attributes: NodeAttributes,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub delta: Option<TextDelta>,

    #[serde(skip_serializing_if = "Vec::is_empty")]
    pub children: Vec<NodeSubTree>,
}

impl NodeSubTree {
    pub fn new(node_type: &str) -> NodeSubTree {
        NodeSubTree {
            note_type: node_type.into(),
            attributes: NodeAttributes::new(),
            delta: None,
            children: Vec::new(),
        }
    }

    pub fn to_node_data(&self) -> NodeData {
        NodeData {
            node_type: self.note_type.clone(),
            attributes: self.attributes.clone(),
            delta: self.delta.clone(),
        }
    }
}
