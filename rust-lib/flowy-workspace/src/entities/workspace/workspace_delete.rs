use crate::{
    entities::workspace::parser::WorkspaceId,
    errors::{ErrorBuilder, WorkspaceError, WsErrCode},
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(Default, ProtoBuf)]
pub struct DeleteWorkspaceRequest {
    #[pb(index = 1)]
    workspace_id: String,
}

#[derive(ProtoBuf, Default)]
pub struct DeleteWorkspaceParams {
    #[pb(index = 1)]
    workspace_id: String,
}

impl TryInto<DeleteWorkspaceParams> for DeleteWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<DeleteWorkspaceParams, Self::Error> {
        let workspace_id = WorkspaceId::parse(self.workspace_id)
            .map_err(|e| {
                ErrorBuilder::new(WsErrCode::WorkspaceIdInvalid)
                    .msg(e)
                    .build()
            })?
            .0;

        Ok(DeleteWorkspaceParams { workspace_id })
    }
}
