use crate::entities::folder::FolderDelta;
use crate::util::make_delta_from_revisions;
use crate::{
    client_folder::{default_folder_delta, FolderPad},
    entities::revision::Revision,
    errors::{CollaborateError, CollaborateResult},
};

use flowy_folder_data_model::revision::{TrashRevision, WorkspaceRevision};
use lib_ot::core::{PhantomAttributes, TextDelta, TextDeltaBuilder};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Serialize, Deserialize)]
pub(crate) struct FolderPadBuilder {
    workspaces: Vec<Arc<WorkspaceRevision>>,
    trash: Vec<Arc<TrashRevision>>,
}

impl FolderPadBuilder {
    pub(crate) fn new() -> Self {
        Self {
            workspaces: vec![],
            trash: vec![],
        }
    }

    pub(crate) fn with_workspace(mut self, workspaces: Vec<WorkspaceRevision>) -> Self {
        self.workspaces = workspaces.into_iter().map(Arc::new).collect();
        self
    }

    pub(crate) fn with_trash(mut self, trash: Vec<TrashRevision>) -> Self {
        self.trash = trash.into_iter().map(Arc::new).collect::<Vec<_>>();
        self
    }

    pub(crate) fn build_with_delta(self, mut delta: TextDelta) -> CollaborateResult<FolderPad> {
        if delta.is_empty() {
            delta = default_folder_delta();
        }

        // TODO: Reconvert from history if delta.to_str() failed.
        let content = delta.content()?;
        let mut folder: FolderPad = serde_json::from_str(&content).map_err(|e| {
            tracing::error!("Deserialize folder from {} failed", content);
            return CollaborateError::internal().context(format!("Deserialize delta to folder failed: {}", e));
        })?;
        folder.delta = delta;
        Ok(folder)
    }

    pub(crate) fn build_with_revisions(self, revisions: Vec<Revision>) -> CollaborateResult<FolderPad> {
        let folder_delta: FolderDelta = make_delta_from_revisions::<PhantomAttributes>(revisions)?;
        self.build_with_delta(folder_delta)
    }

    pub(crate) fn build(self) -> CollaborateResult<FolderPad> {
        let json = serde_json::to_string(&self)
            .map_err(|e| CollaborateError::internal().context(format!("Serialize to folder json str failed: {}", e)))?;
        Ok(FolderPad {
            workspaces: self.workspaces,
            trash: self.trash,
            delta: TextDeltaBuilder::new().insert(&json).build(),
        })
    }
}
