use crate::client_folder::util::*;
use crate::client_folder::AtomicNodeTree;
use flowy_derive::Node;
use lib_ot::core::*;
use std::sync::Arc;

#[derive(Clone, Node)]
#[node_type = "workspace"]
pub struct WorkspaceNode {
    pub tree: Arc<AtomicNodeTree>,
    pub node_id: Option<NodeId>,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub id: String,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub name: String,

    #[node(child_name = "app")]
    pub apps: Vec<AppNode>,
}

impl WorkspaceNode {
    pub fn new(tree: Arc<AtomicNodeTree>, id: String, name: String) -> Self {
        Self {
            tree,
            node_id: None,
            id,
            name,
            apps: vec![],
        }
    }
}

#[derive(Clone, Node)]
#[node_type = "app"]
pub struct AppNode {
    pub tree: Arc<AtomicNodeTree>,
    pub node_id: Option<NodeId>,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub id: String,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub name: String,
}

impl AppNode {
    pub fn new(tree: Arc<AtomicNodeTree>, id: String, name: String) -> Self {
        Self {
            tree,
            node_id: None,
            id,
            name,
        }
    }
}
