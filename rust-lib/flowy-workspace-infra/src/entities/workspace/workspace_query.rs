use crate::{errors::*, parser::workspace::WorkspaceId};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf, Clone)]
pub struct QueryWorkspaceRequest {
    // return all workspace if workspace_id is None
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,
}

impl QueryWorkspaceRequest {
    pub fn new() -> Self { Self { workspace_id: None } }

    pub fn workspace_id(mut self, workspace_id: &str) -> Self {
        self.workspace_id = Some(workspace_id.to_owned());
        self
    }
}

// Read all workspaces if the workspace_id is None
#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct WorkspaceIdentifier {
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,
}

impl WorkspaceIdentifier {
    pub fn new(workspace_id: Option<String>) -> Self { Self { workspace_id } }
}

impl TryInto<WorkspaceIdentifier> for QueryWorkspaceRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<WorkspaceIdentifier, Self::Error> {
        let workspace_id = match self.workspace_id {
            None => None,
            Some(workspace_id) => Some(WorkspaceId::parse(workspace_id)?.0),
        };

        Ok(WorkspaceIdentifier { workspace_id })
    }
}
