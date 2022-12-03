use crate::client_folder::AtomicNodeTree;
use flowy_derive::Node;
use std::sync::Arc;

#[derive(Debug, Clone, Node)]
pub struct WorkspaceNode2 {
    tree: Arc<AtomicNodeTree>,
    #[node]
    pub id: String,
    // pub name: String,
    // pub path: Path,
}
