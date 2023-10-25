use validator::Validate;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_deps::entities::Role;

use crate::entities::required_not_empty_str;

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
  pub uid: i64,

  #[pb(index = 3)]
  pub role: AFRolePB,
}

#[derive(ProtoBuf_Enum, Clone)]
pub enum AFRolePB {
  Owner = 0,
  Member = 1,
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

impl Default for AFRolePB {
  fn default() -> Self {
    AFRolePB::Guest
  }
}
