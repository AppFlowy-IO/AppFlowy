use crate::{errors::*, parser::workspace::WorkspaceIdentify};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf, Clone)]
pub struct QueryWorkspaceRequest {
    // return all workspace if workspace_id is None
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,
}

impl QueryWorkspaceRequest {
    pub fn new(workspace_id: Option<String>) -> Self { Self { workspace_id } }
}

// Read all workspaces if the workspace_id is None
#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct WorkspaceId {
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,
}

impl WorkspaceId {
    pub fn new(workspace_id: Option<String>) -> Self { Self { workspace_id } }
}

impl TryInto<WorkspaceId> for QueryWorkspaceRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<WorkspaceId, Self::Error> {
        let workspace_id = match self.workspace_id {
            None => None,
            Some(workspace_id) => Some(WorkspaceIdentify::parse(workspace_id)?.0),
        };

        Ok(WorkspaceId { workspace_id })
    }
}
