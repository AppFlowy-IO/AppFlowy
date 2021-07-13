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

    #[pb(index = 2, one_of)]
    name: Option<String>,

    #[pb(index = 3, one_of)]
    desc: Option<String>,
}

pub struct UpdateWorkspaceParams {
    pub id: String,
    pub name: Option<String>,
    pub desc: Option<String>,
}

impl TryInto<UpdateWorkspaceParams> for UpdateWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<UpdateWorkspaceParams, Self::Error> {
        let name = match self.name {
            None => None,
            Some(name) => Some(
                WorkspaceName::parse(name)
                    .map_err(|e| {
                        ErrorBuilder::new(WorkspaceErrorCode::WorkspaceNameInvalid)
                            .msg(e)
                            .build()
                    })?
                    .0,
            ),
        };

        let id = WorkspaceId::parse(self.id).map_err(|e| {
            ErrorBuilder::new(WorkspaceErrorCode::WorkspaceIdInvalid)
                .msg(e)
                .build()
        })?;

        Ok(UpdateWorkspaceParams {
            id: id.0,
            name,
            desc: self.desc,
        })
    }
}
