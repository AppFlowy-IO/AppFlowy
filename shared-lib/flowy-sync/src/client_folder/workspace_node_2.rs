use crate::client_folder::AtomicNodeTree;
use crate::errors::CollaborateResult;
use flowy_derive::Node;
use lib_ot::core::*;
use std::sync::Arc;

#[derive(Clone, Node)]
#[node_type = "workspace"]
pub struct WorkspaceNode2 {
    tree: Arc<AtomicNodeTree>,
    path: Path,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub id: String,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    #[node(rename = "name123")]
    pub name: String,

    #[node(get_value_with = "get_attributes_int_value")]
    pub time: i64,

    #[node(children)]
    pub apps: Vec<AppNode2>,
}

#[derive(Clone, Node)]
#[node_type = "app"]
pub struct AppNode2 {
    tree: Arc<AtomicNodeTree>,
    path: Path,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub id: String,

    #[node(get_value_with = "get_attributes_str_value")]
    #[node(set_value_with = "set_attributes_str_value")]
    pub name: String,
}

pub fn get_attributes_str_value(tree: Arc<AtomicNodeTree>, path: &Path, key: &str) -> Option<String> {
    tree.read()
        .get_node_at_path(&path)
        .and_then(|node| node.attributes.get(key).cloned())
        .and_then(|value| value.str_value())
}

pub fn set_attributes_str_value(
    tree: Arc<AtomicNodeTree>,
    path: &Path,
    key: &str,
    value: String,
) -> CollaborateResult<()> {
    let old_attributes = match get_attributes(tree.clone(), path) {
        None => AttributeHashMap::new(),
        Some(attributes) => attributes,
    };
    let mut new_attributes = old_attributes.clone();
    new_attributes.insert(key, value);

    let update_operation = NodeOperation::Update {
        path: path.clone(),
        changeset: Changeset::Attributes {
            new: new_attributes,
            old: old_attributes,
        },
    };
    let _ = tree.write().apply_op(update_operation)?;
    Ok(())
}

pub fn get_attributes_int_value(tree: Arc<AtomicNodeTree>, path: &Path, key: &str) -> Option<i64> {
    tree.read()
        .get_node_at_path(&path)
        .and_then(|node| node.attributes.get(key).cloned())
        .and_then(|value| value.int_value())
}

pub fn get_attributes(tree: Arc<AtomicNodeTree>, path: &Path) -> Option<AttributeHashMap> {
    tree.read()
        .get_node_at_path(&path)
        .and_then(|node| Some(node.attributes.clone()))
}

pub fn get_attributes_value(tree: Arc<AtomicNodeTree>, path: &Path, key: &str) -> Option<AttributeValue> {
    tree.read()
        .get_node_at_path(&path)
        .and_then(|node| node.attributes.get(key).cloned())
}
