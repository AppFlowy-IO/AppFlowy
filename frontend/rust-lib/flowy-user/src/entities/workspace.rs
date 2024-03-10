use validator::Validate;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::{WorkspaceInvitation, WorkspaceMember, WorkspaceRole};
use lib_infra::validator_fn::required_not_empty_str;

#[derive(ProtoBuf, Default, Clone)]
pub struct WorkspaceMemberPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub role: WorkspaceRolePB,
}

impl From<WorkspaceMember> for WorkspaceMemberPB {
  fn from(value: WorkspaceMember) -> Self {
    Self {
      email: value.email,
      name: value.name,
      role: value.role.into(),
    }
  }
}

#[derive(ProtoBuf, Default, Clone)]
pub struct RepeatedWorkspaceMemberPB {
  #[pb(index = 1)]
  pub items: Vec<WorkspaceMemberPB>,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct WorkspaceMemberInvitationPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub invitee_email: String,

  #[pb(index = 3)]
  pub role: WorkspaceRolePB,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct RepeatedWorkspaceInvitationPB {
  #[pb(index = 1)]
  pub items: Vec<WorkspaceInvitationPB>,
}

#[derive(Debug, ProtoBuf, Default, Clone)]
pub struct WorkspaceInvitationPB {
  #[pb(index = 1)]
  pub invite_id: String,
  #[pb(index = 2)]
  pub workspace_id: String,
  #[pb(index = 3)]
  pub workspace_name: String,
  #[pb(index = 4)]
  pub inviter_email: String,
  #[pb(index = 5)]
  pub inviter_name: String,
  #[pb(index = 6)]
  pub status: String,
  #[pb(index = 7)]
  pub updated_at_timestamp: i64,
}

impl From<WorkspaceInvitation> for WorkspaceInvitationPB {
  fn from(value: WorkspaceInvitation) -> Self {
    Self {
      invite_id: value.invite_id.to_string(),
      workspace_id: value.workspace_id.to_string(),
      workspace_name: value.workspace_name.unwrap_or_default(),
      inviter_email: value.inviter_email.unwrap_or_default(),
      inviter_name: value.inviter_name.unwrap_or_default(),
      status: format!("{:?}", value.status),
      updated_at_timestamp: value.updated_at.timestamp(),
    }
  }
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct AcceptWorkspaceInvitationPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub invite_id: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct AddWorkspaceMemberPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub email: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct QueryWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct RemoveWorkspaceMemberPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub email: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct UpdateWorkspaceMemberPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(email)]
  pub email: String,

  #[pb(index = 3)]
  pub role: WorkspaceRolePB,
}

#[derive(ProtoBuf_Enum, Clone, Default)]
pub enum WorkspaceRolePB {
  Owner = 0,
  Member = 1,
  #[default]
  Guest = 2,
}

impl From<WorkspaceRolePB> for WorkspaceRole {
  fn from(value: WorkspaceRolePB) -> Self {
    match value {
      WorkspaceRolePB::Owner => WorkspaceRole::Owner,
      WorkspaceRolePB::Member => WorkspaceRole::Member,
      WorkspaceRolePB::Guest => WorkspaceRole::Guest,
    }
  }
}

impl From<WorkspaceRole> for WorkspaceRolePB {
  fn from(value: WorkspaceRole) -> Self {
    match value {
      WorkspaceRole::Owner => WorkspaceRolePB::Owner,
      WorkspaceRole::Member => WorkspaceRolePB::Member,
      WorkspaceRole::Guest => WorkspaceRolePB::Guest,
    }
  }
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct UserWorkspaceIdPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct CreateWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub name: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct RenameWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  #[validate(custom = "required_not_empty_str")]
  pub new_name: String,
}

#[derive(ProtoBuf, Default, Clone, Validate)]
pub struct ChangeWorkspaceIconPB {
  #[pb(index = 1)]
  #[validate(custom = "required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub new_icon: String,
}
