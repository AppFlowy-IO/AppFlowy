use crate::{
    entities::{app::RepeatedApp, workspace::parser::*},
    errors::*,
    impl_def_and_def_mut,
};
use flowy_derive::ProtoBuf;
use std::convert::TryInto;

#[derive(ProtoBuf, Default)]
pub struct CreateWorkspaceRequest {
    #[pb(index = 1)]
    pub name: String,

    #[pb(index = 2)]
    pub desc: String,
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct CreateWorkspaceParams {
    #[pb(index = 1)]
    pub name: String,

    #[pb(index = 2)]
    pub desc: String,
}

impl TryInto<CreateWorkspaceParams> for CreateWorkspaceRequest {
    type Error = WorkspaceError;

    fn try_into(self) -> Result<CreateWorkspaceParams, Self::Error> {
        let name = WorkspaceName::parse(self.name).map_err(|e| WorkspaceError::workspace_name().context(e))?;
        let desc = WorkspaceDesc::parse(self.desc).map_err(|e| WorkspaceError::workspace_desc().context(e))?;

        Ok(CreateWorkspaceParams {
            name: name.0,
            desc: desc.0,
        })
    }
}

#[derive(PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct Workspace {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2)]
    pub name: String,

    #[pb(index = 3)]
    pub desc: String,

    #[pb(index = 4)]
    pub apps: RepeatedApp,

    #[pb(index = 5)]
    pub modified_time: i64,

    #[pb(index = 6)]
    pub create_time: i64,
}

#[derive(PartialEq, Debug, Default, ProtoBuf)]
pub struct RepeatedWorkspace {
    #[pb(index = 1)]
    pub items: Vec<Workspace>,
}

impl_def_and_def_mut!(RepeatedWorkspace, Workspace);
