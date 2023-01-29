use crate::client_folder::AtomicNodeTree;
use crate::errors::CollaborateResult;
use lib_ot::core::{AttributeHashMap, AttributeValue, Changeset, NodeId, NodeOperation};
use std::sync::Arc;

pub fn get_attributes_str_value(tree: Arc<AtomicNodeTree>, node_id: &NodeId, key: &str) -> Option<String> {
    tree.read()
        .get_node(*node_id)
        .and_then(|node| node.attributes.get(key).cloned())
        .and_then(|value| value.str_value())
}

pub fn set_attributes_str_value(
    tree: Arc<AtomicNodeTree>,
    node_id: &NodeId,
    key: &str,
    value: String,
) -> CollaborateResult<()> {
    let old_attributes = match get_attributes(tree.clone(), node_id) {
        None => AttributeHashMap::new(),
        Some(attributes) => attributes,
    };
    let mut new_attributes = old_attributes.clone();
    new_attributes.insert(key, value);
    let path = tree.read().path_from_node_id(*node_id);
    let update_operation = NodeOperation::Update {
        path,
        changeset: Changeset::Attributes {
            new: new_attributes,
            old: old_attributes,
        },
    };
    tree.write().apply_op(update_operation)?;
    Ok(())
}

#[allow(dead_code)]
pub fn get_attributes_int_value(tree: Arc<AtomicNodeTree>, node_id: &NodeId, key: &str) -> Option<i64> {
    tree.read()
        .get_node(*node_id)
        .and_then(|node| node.attributes.get(key).cloned())
        .and_then(|value| value.int_value())
}

pub fn get_attributes(tree: Arc<AtomicNodeTree>, node_id: &NodeId) -> Option<AttributeHashMap> {
    tree.read().get_node(*node_id).map(|node| node.attributes.clone())
}

#[allow(dead_code)]
pub fn get_attributes_value(tree: Arc<AtomicNodeTree>, node_id: &NodeId, key: &str) -> Option<AttributeValue> {
    tree.read()
        .get_node(*node_id)
        .and_then(|node| node.attributes.get(key).cloned())
}
