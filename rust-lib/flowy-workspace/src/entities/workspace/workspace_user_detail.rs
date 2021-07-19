use crate::entities::workspace::Workspace;
use flowy_derive::ProtoBuf;

#[derive(ProtoBuf, Default, Debug)]
pub struct UserWorkspace {
    #[pb(index = 1)]
    pub owner: String,

    #[pb(index = 2)]
    pub workspace_id: String,
}

#[derive(ProtoBuf, Default, Debug)]
pub struct UserWorkspaceDetail {
    #[pb(index = 1)]
    pub owner: String,

    #[pb(index = 2)]
    pub workspace: Workspace,
}
