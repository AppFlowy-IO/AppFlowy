use crate::{
    entities::{app::RepeatedApp, view::View},
    errors::*,
    impl_def_and_def_mut,
    parser::workspace::{WorkspaceDesc, WorkspaceIdentify, WorkspaceName},
};
use flowy_derive::ProtoBuf;
use serde::{Deserialize, Serialize};
use std::convert::TryInto;

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone, Serialize, Deserialize)]
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
    type Error = ErrorCode;

    fn try_into(self) -> Result<CreateWorkspaceParams, Self::Error> {
        let name = WorkspaceName::parse(self.name)?;
        let desc = WorkspaceDesc::parse(self.desc)?;

        Ok(CreateWorkspaceParams {
            name: name.0,
            desc: desc.0,
        })
    }
}

#[derive(Default, ProtoBuf, Clone)]
pub struct QueryWorkspaceRequest {
    // return all workspace if workspace_id is None
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,
}

impl QueryWorkspaceRequest {
    pub fn new(workspace_id: Option<String>) -> Self { Self { workspace_id } }
}

// Read all workspaces if the workspace_id is None
#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct WorkspaceId {
    #[pb(index = 1, one_of)]
    pub workspace_id: Option<String>,
}

impl WorkspaceId {
    pub fn new(workspace_id: Option<String>) -> Self { Self { workspace_id } }
}

impl TryInto<WorkspaceId> for QueryWorkspaceRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<WorkspaceId, Self::Error> {
        let workspace_id = match self.workspace_id {
            None => None,
            Some(workspace_id) => Some(WorkspaceIdentify::parse(workspace_id)?.0),
        };

        Ok(WorkspaceId { workspace_id })
    }
}

#[derive(Default, ProtoBuf, Clone)]
pub struct CurrentWorkspaceSetting {
    #[pb(index = 1)]
    pub workspace: Workspace,

    #[pb(index = 2, one_of)]
    pub latest_view: Option<View>,
}

#[derive(ProtoBuf, Default)]
pub struct UpdateWorkspaceRequest {
    #[pb(index = 1)]
    id: String,

    #[pb(index = 2, one_of)]
    name: Option<String>,

    #[pb(index = 3, one_of)]
    desc: Option<String>,
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct UpdateWorkspaceParams {
    #[pb(index = 1)]
    pub id: String,

    #[pb(index = 2, one_of)]
    pub name: Option<String>,

    #[pb(index = 3, one_of)]
    pub desc: Option<String>,
}

impl TryInto<UpdateWorkspaceParams> for UpdateWorkspaceRequest {
    type Error = ErrorCode;

    fn try_into(self) -> Result<UpdateWorkspaceParams, Self::Error> {
        let name = match self.name {
            None => None,
            Some(name) => Some(WorkspaceName::parse(name)?.0),
        };
        let id = WorkspaceIdentify::parse(self.id)?;

        Ok(UpdateWorkspaceParams {
            id: id.0,
            name,
            desc: self.desc,
        })
    }
}
