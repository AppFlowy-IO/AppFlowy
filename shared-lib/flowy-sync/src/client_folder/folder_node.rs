use crate::client_folder::workspace_node::WorkspaceNode;
use crate::errors::{CollaborateError, CollaborateResult};
use folder_rev_model::{AppRevision, ViewRevision, WorkspaceRevision};
use lib_ot::core::{
    AttributeEntry, AttributeHashMap, AttributeValue, Changeset, Node, NodeDataBuilder, NodeOperation, NodeTree, Path,
    Transaction,
};
use parking_lot::RwLock;
use std::string::ToString;
use std::sync::Arc;

pub type AtomicNodeTree = RwLock<NodeTree>;

pub struct FolderNodePad {
    tree: Arc<AtomicNodeTree>,
    workspaces: Vec<Arc<WorkspaceNode>>,
    trash: Vec<Arc<TrashNode>>,
}

impl FolderNodePad {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn get_workspace(&self, workspace_id: &str) -> Option<&Arc<WorkspaceNode>> {
        self.workspaces.iter().find(|workspace| workspace.id == workspace_id)
    }

    pub fn get_mut_workspace(&mut self, workspace_id: &str) -> Option<&mut Arc<WorkspaceNode>> {
        self.workspaces
            .iter_mut()
            .find(|workspace| workspace.id == workspace_id)
    }

    pub fn remove_workspace(&mut self, workspace_id: &str) {
        if let Some(workspace) = self.workspaces.iter().find(|workspace| workspace.id == workspace_id) {
            let mut nodes = vec![];
            let workspace_node = self.tree.read().get_node_data_at_path(&workspace.path);
            debug_assert!(workspace_node.is_some());

            if let Some(node_data) = workspace_node {
                nodes.push(node_data);
            }
            let delete_operation = NodeOperation::Delete {
                path: workspace.path.clone(),
                nodes,
            };
            let _ = self.tree.write().apply_op(delete_operation);
        }
    }

    pub fn add_workspace(&mut self, revision: WorkspaceRevision) -> CollaborateResult<()> {
        let mut transaction = Transaction::new();
        let workspace_node = WorkspaceNode::from_workspace_revision(
            &mut transaction,
            revision,
            self.tree.clone(),
            workspaces_path().clone_with(self.workspaces.len()),
        )?;
        let _ = self.tree.write().apply_transaction(transaction)?;
        self.workspaces.push(Arc::new(workspace_node));
        Ok(())
    }

    pub fn to_json(&self, pretty: bool) -> CollaborateResult<String> {
        self.tree
            .read()
            .to_json(pretty)
            .map_err(|e| CollaborateError::serde().context(e))
    }
}

fn folder_path() -> Path {
    vec![0].into()
}

fn workspaces_path() -> Path {
    folder_path().clone_with(0)
}

fn trash_path() -> Path {
    folder_path().clone_with(1)
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

impl std::default::Default for FolderNodePad {
    fn default() -> Self {
        let workspace_node = NodeDataBuilder::new("workspaces").build();
        let trash_node = NodeDataBuilder::new("trash").build();
        let folder_node = NodeDataBuilder::new("folder")
            .add_node_data(workspace_node)
            .add_node_data(trash_node)
            .build();

        let operation = NodeOperation::Insert {
            path: folder_path(),
            nodes: vec![folder_node],
        };
        let mut tree = NodeTree::default();
        let _ = tree.apply_op(operation).unwrap();

        Self {
            tree: Arc::new(RwLock::new(tree)),
            workspaces: vec![],
            trash: vec![],
        }
    }
}

pub struct TrashNode {
    tree: Arc<AtomicNodeTree>,
    parent_path: Path,
}
