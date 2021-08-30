use crate::{entities::workspace::parser::*, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryWorkspaceRequest {
    // return all workspace if workspace_id is None
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,

    #[pb(index = 2)]
    pub user_id: String,
}

// Read all workspaces if the workspace_id is None
#[derive(ProtoBuf, Default)]
pub struct QueryWorkspaceParams {
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,

    #[pb(index = 2)]
    pub user_id: String,
}

impl QueryWorkspaceParams {
    pub fn new(user_id: &str) -> Self {
        Self {
            workspace_id: None,
            user_id: user_id.to_owned(),
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
                    .map_err(|e| {
                        ErrorBuilder::new(WsErrCode::WorkspaceIdInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        Ok(QueryWorkspaceParams {
            workspace_id,
            user_id: self.user_id,
        })
    }
}
