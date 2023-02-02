use crate::client_folder::util::*;
use crate::client_folder::AtomicNodeTree;
use flowy_derive::Node;
use lib_ot::core::*;
use std::sync::Arc;

#[derive(Clone, Node)]
#[node_type = "trash"]
pub struct TrashNode {
    pub tree: Arc<AtomicNodeTree>,
    pub node_id: Option<NodeId>,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub id: String,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub name: String,
}
