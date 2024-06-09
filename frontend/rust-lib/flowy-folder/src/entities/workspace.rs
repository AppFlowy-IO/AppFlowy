use std::convert::TryInto;

use collab::core::collab_state::SyncState;
use collab_folder::Workspace;

use flowy_derive::ProtoBuf;
use flowy_error::ErrorCode;

use crate::{
  entities::parser::workspace::{WorkspaceDesc, WorkspaceIdentify, WorkspaceName},
  entities::view::ViewPB,
};

#[derive(Eq, PartialEq, ProtoBuf, Default, Debug, Clone)]
pub struct WorkspacePB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub views: Vec<ViewPB>,

  #[pb(index = 4)]
  pub create_time: i64,
}

impl std::convert::From<(Workspace, Vec<ViewPB>)> for WorkspacePB {
  fn from(params: (Workspace, Vec<ViewPB>)) -> Self {
    let (workspace, views) = params;
    WorkspacePB {
      id: workspace.id,
      name: workspace.name,
      views,
      create_time: workspace.created_at,
    }
  }
}

// impl std::convert::From<Workspace> for WorkspacePB {
//   fn from(workspace: Workspace) -> Self {
//     WorkspacePB {
//       id: workspace.id,
//       name: workspace.name,
//       views: Default::default(),
//       create_time: workspace.created_at,
//     }
//   }
// }

#[derive(PartialEq, Eq, Debug, Default, ProtoBuf)]
pub struct RepeatedWorkspacePB {
  #[pb(index = 1)]
  pub items: Vec<WorkspacePB>,
}

impl From<Vec<WorkspacePB>> for RepeatedWorkspacePB {
  fn from(workspaces: Vec<WorkspacePB>) -> Self {
    Self { items: workspaces }
  }
}

#[derive(ProtoBuf, Default)]
pub struct CreateWorkspacePayloadPB {
  #[pb(index = 1)]
  pub name: String,

  #[pb(index = 2)]
  pub desc: String,
}

#[derive(Clone, Debug)]
pub struct CreateWorkspaceParams {
  pub name: String,
  pub desc: String,
}

impl TryInto<CreateWorkspaceParams> for CreateWorkspacePayloadPB {
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

// Read all workspaces if the workspace_id is None
#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct WorkspaceIdPB {
  #[pb(index = 1)]
  pub value: String,
}

#[derive(Clone, Debug)]
pub struct WorkspaceIdParams {
  pub value: String,
}

impl TryInto<WorkspaceIdParams> for WorkspaceIdPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<WorkspaceIdParams, Self::Error> {
    Ok(WorkspaceIdParams {
      value: WorkspaceIdentify::parse(self.value)?.0,
    })
  }
}

#[derive(Clone, ProtoBuf, Default, Debug)]
pub struct GetWorkspaceViewPB {
  #[pb(index = 1)]
  pub value: String,
}

#[derive(Clone, Debug)]
pub struct GetWorkspaceViewParams {
  pub value: String,
}

impl TryInto<GetWorkspaceViewParams> for GetWorkspaceViewPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<GetWorkspaceViewParams, Self::Error> {
    Ok(GetWorkspaceViewParams {
      value: WorkspaceIdentify::parse(self.value)?.0,
    })
  }
}

#[derive(Default, ProtoBuf, Debug, Clone)]
pub struct WorkspaceSettingPB {
  #[pb(index = 1)]
  pub workspace_id: String,

  #[pb(index = 2, one_of)]
  pub latest_view: Option<ViewPB>,
}

#[derive(ProtoBuf, Default)]
pub struct UpdateWorkspacePayloadPB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2, one_of)]
  pub name: Option<String>,

  #[pb(index = 3, one_of)]
  pub desc: Option<String>,
}

#[derive(Clone, Debug)]
pub struct UpdateWorkspaceParams {
  pub id: String,
  pub name: Option<String>,
  pub desc: Option<String>,
}

impl TryInto<UpdateWorkspaceParams> for UpdateWorkspacePayloadPB {
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

#[derive(Debug, Default, ProtoBuf)]
pub struct RepeatedFolderSnapshotPB {
  #[pb(index = 1)]
  pub items: Vec<FolderSnapshotPB>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct FolderSnapshotPB {
  #[pb(index = 1)]
  pub snapshot_id: i64,

  #[pb(index = 2)]
  pub snapshot_desc: String,

  #[pb(index = 3)]
  pub created_at: i64,

  #[pb(index = 4)]
  pub data: Vec<u8>,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct FolderSnapshotStatePB {
  #[pb(index = 1)]
  pub new_snapshot_id: i64,
}

#[derive(Debug, Default, ProtoBuf)]
pub struct FolderSyncStatePB {
  #[pb(index = 1)]
  pub is_syncing: bool,

  #[pb(index = 2)]
  pub is_finish: bool,
}

impl From<SyncState> for FolderSyncStatePB {
  fn from(value: SyncState) -> Self {
    Self {
      is_syncing: value.is_syncing(),
      is_finish: value.is_sync_finished(),
    }
  }
}

#[derive(ProtoBuf, Default)]
pub struct UserFolderPB {
  #[pb(index = 1)]
  pub uid: i64,

  #[pb(index = 2)]
  pub workspace_id: String,
}
