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

pub struct QueryWorkspaceParams {
    pub workspace_id: String,
    pub read_apps: bool,
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
