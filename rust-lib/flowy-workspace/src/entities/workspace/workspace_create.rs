use crate::{entities::workspace::workspace_name::WorkspaceName, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct CreateWorkspaceRequest {
    #[pb(index = 1)]
    name: String,

    #[pb(index = 2)]
    desc: String,
}

pub struct CreateWorkspaceParams {
    pub name: String,
    pub desc: String,
}

impl TryInto<CreateWorkspaceParams> for CreateWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<CreateWorkspaceParams, Self::Error> {
        let name = WorkspaceName::parse(self.name).map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::WorkspaceNameInvalid)
                .msg(e)
                .build()
        })?;

        Ok(CreateWorkspaceParams {
            name: name.0,
            desc: self.desc,
        })
    }
}
