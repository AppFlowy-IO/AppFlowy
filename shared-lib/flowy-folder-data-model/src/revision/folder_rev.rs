use crate::revision::{TrashRevision, WorkspaceRevision};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Debug, Default, Deserialize, Serialize, Clone, Eq, PartialEq)]
pub struct FolderRevision {
    pub workspaces: Vec<Arc<WorkspaceRevision>>,
    pub trash: Vec<Arc<TrashRevision>>,
}
