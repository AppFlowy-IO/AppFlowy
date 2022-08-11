use crate::entities::folder::FolderDelta;
use crate::util::make_delta_from_revisions;
use crate::{
    client_folder::{default_folder_delta, FolderPad},
    entities::revision::Revision,
    errors::CollaborateResult,
};

use flowy_folder_data_model::revision::{TrashRevision, WorkspaceRevision};
use lib_ot::core::PhantomAttributes;
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
        let mut folder_delta: FolderDelta = make_delta_from_revisions::<PhantomAttributes>(revisions)?;
        if folder_delta.is_empty() {
            folder_delta = default_folder_delta();
        }
        FolderPad::from_delta(folder_delta)
    }

    #[allow(dead_code)]
    pub(crate) fn build(self) -> CollaborateResult<FolderPad> {
        FolderPad::new(self.workspaces, self.trash)
    }
}
