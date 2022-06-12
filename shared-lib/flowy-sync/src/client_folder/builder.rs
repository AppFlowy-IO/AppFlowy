use crate::entities::folder_info::FolderDelta;
use crate::util::make_delta_from_revisions;
use crate::{
    client_folder::{default_folder_delta, FolderPad},
    entities::revision::Revision,
    errors::{CollaborateError, CollaborateResult},
};

use flowy_folder_data_model::entities::{Trash, Workspace};
use flowy_folder_data_model::revision::{TrashRevision, WorkspaceRevision};
use lib_ot::core::{PlainTextAttributes, PlainTextDelta, PlainTextDeltaBuilder};
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

    pub(crate) fn with_workspace(mut self, workspaces: Vec<Workspace>) -> Self {
        self.workspaces = workspaces
            .into_iter()
            .map(|workspace| Arc::new(workspace.into()))
            .collect::<Vec<_>>();
        self
    }

    pub(crate) fn with_trash(mut self, trash: Vec<Trash>) -> Self {
        self.trash = trash.into_iter().map(|t| Arc::new(t.into())).collect::<Vec<_>>();
        self
    }

    pub(crate) fn build_with_delta(self, mut delta: PlainTextDelta) -> CollaborateResult<FolderPad> {
        if delta.is_empty() {
            delta = default_folder_delta();
        }

        // TODO: Reconvert from history if delta.to_str() failed.
        let folder_json = delta.to_str()?;
        let mut folder: FolderPad = serde_json::from_str(&folder_json).map_err(|e| {
            tracing::error!("Deserialize folder from json failed: {}", folder_json);
            return CollaborateError::internal().context(format!("Deserialize delta to folder failed: {}", e));
        })?;
        folder.delta = delta;
        Ok(folder)
    }

    pub(crate) fn build_with_revisions(self, revisions: Vec<Revision>) -> CollaborateResult<FolderPad> {
        let folder_delta: FolderDelta = make_delta_from_revisions::<PlainTextAttributes>(revisions)?;
        self.build_with_delta(folder_delta)
    }

    pub(crate) fn build(self) -> CollaborateResult<FolderPad> {
        let json = serde_json::to_string(&self)
            .map_err(|e| CollaborateError::internal().context(format!("Serialize to folder json str failed: {}", e)))?;
        Ok(FolderPad {
            workspaces: self.workspaces,
            trash: self.trash,
            delta: PlainTextDeltaBuilder::new().insert(&json).build(),
        })
    }
}
