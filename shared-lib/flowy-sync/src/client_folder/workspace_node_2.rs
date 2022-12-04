use crate::client_folder::util::*;
use crate::client_folder::AtomicNodeTree;
use crate::errors::CollaborateResult;
use flowy_derive::Node;
use lib_ot::core::*;
use std::sync::Arc;

#[derive(Clone, Node)]
#[node_type = "workspace"]
pub struct WorkspaceNode2 {
    tree: Arc<AtomicNodeTree>,
    node_id: NodeId,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub id: String,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    #[node(rename = "name123")]
    pub name: String,

    #[node(get_value_with = "get_attributes_int_value")]
    pub time: i64,

    #[node(child_name = "app")]
    pub apps: Vec<AppNode2>,
}

#[derive(Clone, Node)]
#[node_type = "app"]
pub struct AppNode2 {
    tree: Arc<AtomicNodeTree>,
    node_id: NodeId,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub id: String,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub name: String,
}
