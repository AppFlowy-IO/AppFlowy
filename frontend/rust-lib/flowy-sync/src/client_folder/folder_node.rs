use crate::client_folder::trash_node::TrashNode;
use crate::client_folder::workspace_node::WorkspaceNode;
use crate::errors::{CollaborateError, CollaborateResult};
use flowy_derive::Node;
use lib_ot::core::NodeTree;
use lib_ot::core::*;
use parking_lot::RwLock;
use std::sync::Arc;

pub type AtomicNodeTree = RwLock<NodeTree>;

pub struct FolderNodePad {
    pub tree: Arc<AtomicNodeTree>,
    pub node_id: NodeId,
    pub workspaces: WorkspaceList,
    pub trash: TrashList,
}

#[derive(Clone, Node)]
#[node_type = "workspaces"]
pub struct WorkspaceList {
    pub tree: Arc<AtomicNodeTree>,
    pub node_id: Option<NodeId>,

    #[node(child_name = "workspace")]
    inner: Vec<WorkspaceNode>,
}

impl std::ops::Deref for WorkspaceList {
    type Target = Vec<WorkspaceNode>;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl std::ops::DerefMut for WorkspaceList {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.inner
    }
}

#[derive(Clone, Node)]
#[node_type = "trash"]
pub struct TrashList {
    pub tree: Arc<AtomicNodeTree>,
    pub node_id: Option<NodeId>,

    #[node(child_name = "trash")]
    inner: Vec<TrashNode>,
}

impl FolderNodePad {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn get_workspace(&self, workspace_id: &str) -> Option<&WorkspaceNode> {
        self.workspaces.iter().find(|workspace| workspace.id == workspace_id)
    }

    pub fn get_mut_workspace(&mut self, workspace_id: &str) -> Option<&mut WorkspaceNode> {
        self.workspaces
            .iter_mut()
            .find(|workspace| workspace.id == workspace_id)
    }

    pub fn add_workspace(&mut self, mut workspace: WorkspaceNode) {
        let path = workspaces_path().clone_with(self.workspaces.len());
        let op = NodeOperation::Insert {
            path: path.clone(),
            nodes: vec![workspace.to_node_data()],
        };
        self.tree.write().apply_op(op).unwrap();

        let node_id = self.tree.read().node_id_at_path(path).unwrap();
        workspace.node_id = Some(node_id);
        self.workspaces.push(workspace);
    }

    pub fn to_json(&self, pretty: bool) -> CollaborateResult<String> {
        self.tree
            .read()
            .to_json(pretty)
            .map_err(|e| CollaborateError::serde().context(e))
    }
}

impl std::default::Default for FolderNodePad {
    fn default() -> Self {
        let tree = Arc::new(RwLock::new(NodeTree::default()));

        // Workspace
        let mut workspaces = WorkspaceList {
            tree: tree.clone(),
            node_id: None,
            inner: vec![],
        };
        let workspace_node = workspaces.to_node_data();

        // Trash
        let mut trash = TrashList {
            tree: tree.clone(),
            node_id: None,
            inner: vec![],
        };
        let trash_node = trash.to_node_data();

        let folder_node = NodeDataBuilder::new("folder")
            .add_node_data(workspace_node)
            .add_node_data(trash_node)
            .build();

        let operation = NodeOperation::Insert {
            path: folder_path(),
            nodes: vec![folder_node],
        };
        tree.write().apply_op(operation).unwrap();
        let node_id = tree.read().node_id_at_path(folder_path()).unwrap();
        workspaces.node_id = Some(tree.read().node_id_at_path(workspaces_path()).unwrap());
        trash.node_id = Some(tree.read().node_id_at_path(trash_path()).unwrap());

        Self {
            tree,
            node_id,
            workspaces,
            trash,
        }
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
