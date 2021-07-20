use crate::{entities::workspace::parser::*, errors::*};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct CreateWorkspaceRequest {
    #[pb(index = 1)]
    pub name: String,

    #[pb(index = 2)]
    pub desc: String,
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

#[derive(ProtoBuf, Default, Debug)]
pub struct Workspace {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,
}
