use crate::{errors::ErrorCode, parser::workspace::WorkspaceId};
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
    pub workspace_id: String,
}

impl TryInto<DeleteWorkspaceParams> for DeleteWorkspaceRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<DeleteWorkspaceParams, Self::Error> {
        let workspace_id = WorkspaceId::parse(self.workspace_id)?.0;

        Ok(DeleteWorkspaceParams { workspace_id })
    }
}
