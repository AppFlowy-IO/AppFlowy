use crate::util::make_operations_from_revisions;
use crate::{
    client_folder::{default_folder_operations, FolderPad},
    errors::CollaborateResult,
};

use crate::server_folder::FolderOperations;
use flowy_http_model::revision::Revision;
use folder_rev_model::{TrashRevision, WorkspaceRevision};
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize)]
pub(crate) struct FolderPadBuilder {
    workspaces: Vec<WorkspaceRevision>,
    trash: Vec<TrashRevision>,
}

impl FolderPadBuilder {
    pub(crate) fn new() -> Self {
        Self {
            workspaces: vec![],
            trash: vec![],
        }
    }

    #[allow(dead_code)]
    pub(crate) fn with_workspace(mut self, workspaces: Vec<WorkspaceRevision>) -> Self {
        self.workspaces = workspaces;
        self
    }

    #[allow(dead_code)]
    pub(crate) fn with_trash(mut self, trash: Vec<TrashRevision>) -> Self {
        self.trash = trash;
        self
    }

    pub(crate) fn build_with_revisions(self, revisions: Vec<Revision>) -> CollaborateResult<FolderPad> {
        let mut operations: FolderOperations = make_operations_from_revisions(revisions)?;
        if operations.is_empty() {
            operations = default_folder_operations();
        }
        FolderPad::from_operations(operations)
    }

    #[allow(dead_code)]
    pub(crate) fn build(self) -> CollaborateResult<FolderPad> {
        FolderPad::new(self.workspaces, self.trash)
    }
}
