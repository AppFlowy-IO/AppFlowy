use validator::Validate;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::{Role, WorkspaceMember};
use lib_infra::validator_fn::required_not_empty_str;

#[derive(ProtoBuf, Default, Clone)]
pub struct WorkspaceMemberPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub role: AFRolePB,
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
  pub role: AFRolePB,
}

#[derive(ProtoBuf_Enum, Clone, Default)]
pub enum AFRolePB {
  Owner = 0,
  Member = 1,
  #[default]
  Guest = 2,
}

impl From<AFRolePB> for Role {
  fn from(value: AFRolePB) -> Self {
    match value {
      AFRolePB::Owner => Role::Owner,
      AFRolePB::Member => Role::Member,
      AFRolePB::Guest => Role::Guest,
    }
  }
}

impl From<Role> for AFRolePB {
  fn from(value: Role) -> Self {
    match value {
      Role::Owner => AFRolePB::Owner,
      Role::Member => AFRolePB::Member,
      Role::Guest => AFRolePB::Guest,
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
