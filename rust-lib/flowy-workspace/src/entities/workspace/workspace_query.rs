use crate::{entities::workspace::parser::*, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
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
pub struct QueryWorkspaceParams {
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,
}

impl QueryWorkspaceParams {
    pub fn new() -> Self {
        Self {
            workspace_id: None,
            ..Default::default()
        }
    }

    pub fn workspace_id(mut self, workspace_id: &str) -> Self {
        self.workspace_id = Some(workspace_id.to_string());
        self
    }
}

impl TryInto<QueryWorkspaceParams> for QueryWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryWorkspaceParams, Self::Error> {
        let workspace_id = match self.workspace_id {
            None => None,
            Some(workspace_id) => Some(
                WorkspaceId::parse(workspace_id)
                    .map_err(|e| ErrorBuilder::new(ErrorCode::WorkspaceIdInvalid).msg(e).build())?
                    .0,
            ),
        };

        Ok(QueryWorkspaceParams { workspace_id })
    }
}
