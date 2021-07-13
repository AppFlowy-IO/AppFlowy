use crate::{
    entities::workspace::{workspace_id::WorkspaceId, workspace_name::WorkspaceName},
    errors::*,
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct UpdateWorkspaceRequest {
    #[pb(index = 1)]
    id: String,

    #[pb(index = 2)]
    name: String,

    #[pb(index = 3)]
    desc: String,
}

pub struct UpdateWorkspaceParams {
    pub id: String,
    pub name: String,
    pub desc: String,
}

impl TryInto<UpdateWorkspaceParams> for UpdateWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<UpdateWorkspaceParams, Self::Error> {
        let name = WorkspaceName::parse(self.name).map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::WorkspaceNameInvalid)
                .msg(e)
                .build()
        })?;

        let id = WorkspaceId::parse(self.id).map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::WorkspaceIdInvalid)
                .msg(e)
                .build()
        })?;

        Ok(UpdateWorkspaceParams {
            id: id.0,
            name: name.0,
            desc: self.desc,
        })
    }
}
