use crate::{entities::workspace::parser::*, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct QueryWorkspaceRequest {
    #[pb(index = 1)]
    pub workspace_id: String,

    #[pb(index = 2)]
    pub read_apps: bool,
}

#[derive(ProtoBuf, Default)]
pub struct QueryWorkspaceParams {
    #[pb(index = 1)]
    pub workspace_id: String,

    #[pb(index = 2)]
    pub read_apps: bool,
}

impl QueryWorkspaceParams {
    pub fn new(workspace_id: &str) -> Self {
        Self {
            workspace_id: workspace_id.to_owned(),
            ..Default::default()
        }
    }

    pub fn read_apps(mut self) -> Self {
        self.read_apps = true;
        self
    }
}

impl TryInto<QueryWorkspaceParams> for QueryWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<QueryWorkspaceParams, Self::Error> {
        let workspace_id = WorkspaceId::parse(self.workspace_id)
            .map_err(|e| {
                ErrorBuilder::new(WsErrCode::WorkspaceIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        Ok(QueryWorkspaceParams {
            workspace_id,
            read_apps: self.read_apps,
        })
    }
}
