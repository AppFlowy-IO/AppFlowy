use super::AFRolePB;
use crate::entities::parser::{UserEmail, UserIcon, UserName};
use crate::entities::AuthTypePB;
use crate::errors::ErrorCode;
use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::*;
use flowy_user_pub::sql::UserWorkspaceTable;
use lib_infra::validator_fn::required_not_empty_str;
use std::convert::TryInto;
use validator::Validate;

#[derive(Default, ProtoBuf)]
pub struct UserTokenPB {
  #[pb(index = 1)]
  pub token: String,
}

#[derive(ProtoBuf, Default, Clone)]
pub struct UserSettingPB {
  #[pb(index = 1)]
  pub(crate) user_folder: String,
}

#[derive(ProtoBuf, Default, Eq, PartialEq, Debug, Clone)]
pub struct UserProfilePB {
  #[pb(index = 1)]
  pub id: i64,

  #[pb(index = 2)]
  pub email: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4)]
  pub token: String,

  #[pb(index = 5)]
  pub icon_url: String,

  #[pb(index = 6)]
  pub auth_type: AuthTypePB,
}

#[derive(ProtoBuf_Enum, Eq, PartialEq, Debug, Clone)]
pub enum EncryptionTypePB {
  NoEncryption = 0,
  Symmetric = 1,
}

impl Default for EncryptionTypePB {
  fn default() -> Self {
    Self::NoEncryption
  }
}

impl From<UserProfile> for UserProfilePB {
  fn from(user_profile: UserProfile) -> Self {
    Self {
      id: user_profile.uid,
      email: user_profile.email,
      name: user_profile.name,
      token: user_profile.token,
      icon_url: user_profile.icon_url,
      auth_type: user_profile.auth_type.into(),
    }
  }
}

#[derive(ProtoBuf, Default)]
pub struct UpdateUserProfilePayloadPB {
  #[pb(index = 1)]
  pub id: i64,

  #[pb(index = 2, one_of)]
  pub name: Option<String>,

  #[pb(index = 3, one_of)]
  pub email: Option<String>,

  #[pb(index = 4, one_of)]
  pub password: Option<String>,

  #[pb(index = 5, one_of)]
  pub icon_url: Option<String>,
}

impl UpdateUserProfilePayloadPB {
  pub fn new(id: i64) -> Self {
    Self {
      id,
      ..Default::default()
    }
  }

  pub fn name(mut self, name: &str) -> Self {
    self.name = Some(name.to_owned());
    self
  }

  pub fn email(mut self, email: &str) -> Self {
    self.email = Some(email.to_owned());
    self
  }

  pub fn password(mut self, password: &str) -> Self {
    self.password = Some(password.to_owned());
    self
  }

  pub fn icon_url(mut self, icon_url: &str) -> Self {
    self.icon_url = Some(icon_url.to_owned());
    self
  }
}

impl TryInto<UpdateUserProfileParams> for UpdateUserProfilePayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<UpdateUserProfileParams, Self::Error> {
    let name = match self.name {
      None => None,
      Some(name) => Some(UserName::parse(name)?.0),
    };

    let email = match self.email {
      None => None,
      Some(email) => Some(UserEmail::parse(email)?.0),
    };

    let password = self.password;

    let icon_url = match self.icon_url {
      None => None,
      Some(icon_url) => Some(UserIcon::parse(icon_url)?.0),
    };

    Ok(UpdateUserProfileParams {
      uid: self.id,
      name,
      email,
      password,
      icon_url,
      token: None,
    })
  }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedUserWorkspacePB {
  #[pb(index = 1)]
  pub items: Vec<UserWorkspacePB>,
}

impl From<(AuthType, Vec<UserWorkspace>)> for RepeatedUserWorkspacePB {
  fn from(value: (AuthType, Vec<UserWorkspace>)) -> Self {
    let (auth_type, workspaces) = value;
    Self {
      items: workspaces
        .into_iter()
        .map(|w| UserWorkspacePB::from((auth_type, w)))
        .collect(),
    }
  }
}

#[derive(ProtoBuf, Default, Debug, Clone, Validate)]
pub struct UserWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom(function = "required_not_empty_str"))]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub created_at_timestamp: i64,

  #[pb(index = 4)]
  pub icon: String,

  #[pb(index = 5)]
  pub member_count: i64,

  #[pb(index = 6, one_of)]
  pub role: Option<AFRolePB>,

  #[pb(index = 7)]
  pub workspace_auth_type: AuthTypePB,
}

impl From<(AuthType, UserWorkspace)> for UserWorkspacePB {
  fn from(value: (AuthType, UserWorkspace)) -> Self {
    Self {
      workspace_id: value.1.id,
      name: value.1.name,
      created_at_timestamp: value.1.created_at.timestamp(),
      icon: value.1.icon,
      member_count: value.1.member_count,
      role: value.1.role.map(AFRolePB::from),
      workspace_auth_type: AuthTypePB::from(value.0),
    }
  }
}

impl From<UserWorkspaceTable> for UserWorkspacePB {
  fn from(value: UserWorkspaceTable) -> Self {
    Self {
      workspace_id: value.id,
      name: value.name,
      created_at_timestamp: value.created_at,
      icon: value.icon,
      member_count: value.member_count,
      role: value.role.map(AFRolePB::from),
      workspace_auth_type: AuthTypePB::from(value.workspace_type),
    }
  }
}

#[derive(ProtoBuf, Default, Clone)]
pub struct ResetWorkspacePB {
  #[pb(index = 1)]
  pub uid: i64,

  #[pb(index = 2)]
  pub workspace_id: String,
}
