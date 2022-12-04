use crate::client_folder::workspace_node_2::WorkspaceNode2;
use crate::errors::{CollaborateError, CollaborateResult};
use flowy_derive::Node;
use lib_ot::core::NodeTree;
use lib_ot::core::*;
use parking_lot::RwLock;
use std::sync::Arc;

pub type AtomicNodeTree = RwLock<NodeTree>;

#[derive(Node)]
#[node_type = "folder"]
pub struct FolderNodePad2 {
    tree: Arc<AtomicNodeTree>,
    node_id: NodeId,
    // name: workspaces, index of the node,
    #[node(child_name = "child")]
    children: Vec<Box<dyn ToNodeData>>,
}

impl FolderNodePad2 {
    pub fn new() -> Self {
        // let workspace_node = NodeDataBuilder::new("workspaces").build();
        // let trash_node = NodeDataBuilder::new("trash").build();
        // let folder_node = NodeDataBuilder::new("folder")
        //     .add_node_data(workspace_node)
        //     .add_node_data(trash_node)
        //     .build();
        //
        // let operation = NodeOperation::Insert {
        //     path: folder_path(),
        //     nodes: vec![folder_node],
        // };
        // let mut tree = NodeTree::default();
        // let _ = tree.apply_op(operation).unwrap();
        //
        // Self {
        //     tree: Arc::new(RwLock::new(tree)),
        //     workspaces: vec![],
        //     trash: vec![],
        // }
        todo!()
    }

    pub fn to_json(&self, pretty: bool) -> CollaborateResult<String> {
        self.tree
            .read()
            .to_json(pretty)
            .map_err(|e| CollaborateError::serde().context(e))
    }
}
