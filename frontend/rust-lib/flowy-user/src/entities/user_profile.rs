use std::convert::TryInto;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_deps::entities::*;

use crate::entities::parser::{UserEmail, UserIcon, UserName, UserOpenaiKey, UserPassword};
use crate::entities::AuthTypePB;
use crate::errors::ErrorCode;
use crate::services::entities::HistoricalUser;

use super::parser::UserStabilityAIKey;

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
  pub openai_key: String,

  #[pb(index = 7)]
  pub auth_type: AuthTypePB,

  #[pb(index = 8)]
  pub encryption_sign: String,

  #[pb(index = 9)]
  pub encryption_type: EncryptionTypePB,

  #[pb(index = 10)]
  pub workspace_id: String,

  #[pb(index = 11)]
  pub stability_ai_key: String,
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

impl std::convert::From<UserProfile> for UserProfilePB {
  fn from(user_profile: UserProfile) -> Self {
    let (encryption_sign, encryption_ty) = match user_profile.encryption_type {
      EncryptionType::NoEncryption => ("".to_string(), EncryptionTypePB::NoEncryption),
      EncryptionType::SelfEncryption(sign) => (sign, EncryptionTypePB::Symmetric),
    };
    Self {
      id: user_profile.uid,
      email: user_profile.email,
      name: user_profile.name,
      token: user_profile.token,
      icon_url: user_profile.icon_url,
      openai_key: user_profile.openai_key,
      auth_type: user_profile.auth_type.into(),
      encryption_sign,
      encryption_type: encryption_ty,
      workspace_id: user_profile.workspace_id,
      stability_ai_key: user_profile.stability_ai_key,
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

  #[pb(index = 6, one_of)]
  pub openai_key: Option<String>,

  #[pb(index = 7, one_of)]
  pub stability_ai_key: Option<String>,
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

  pub fn openai_key(mut self, openai_key: &str) -> Self {
    self.openai_key = Some(openai_key.to_owned());
    self
  }

  pub fn stability_ai_key(mut self, stability_ai_key: &str) -> Self {
    self.stability_ai_key = Some(stability_ai_key.to_owned());
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

    let password = match self.password {
      None => None,
      Some(password) => Some(UserPassword::parse(password)?.0),
    };

    let icon_url = match self.icon_url {
      None => None,
      Some(icon_url) => Some(UserIcon::parse(icon_url)?.0),
    };

    let openai_key = match self.openai_key {
      None => None,
      Some(openai_key) => Some(UserOpenaiKey::parse(openai_key)?.0),
    };

    let stability_ai_key = match self.stability_ai_key {
      None => None,
      Some(stability_ai_key) => Some(UserStabilityAIKey::parse(stability_ai_key)?.0),
    };

    Ok(UpdateUserProfileParams {
      uid: self.id,
      name,
      email,
      password,
      icon_url,
      openai_key,
      encryption_sign: None,
      token: None,
      stability_ai_key,
    })
  }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct RepeatedUserWorkspacePB {
  #[pb(index = 1)]
  pub items: Vec<UserWorkspacePB>,
}

impl From<Vec<UserWorkspace>> for RepeatedUserWorkspacePB {
  fn from(workspaces: Vec<UserWorkspace>) -> Self {
    Self {
      items: workspaces.into_iter().map(UserWorkspacePB::from).collect(),
    }
  }
}

#[derive(ProtoBuf, Default, Debug, Clone)]
pub struct UserWorkspacePB {
  #[pb(index = 1)]
  pub id: String,

  #[pb(index = 2)]
  pub name: String,
}

impl From<UserWorkspace> for UserWorkspacePB {
  fn from(value: UserWorkspace) -> Self {
    Self {
      id: value.id,
      name: value.name,
    }
  }
}

#[derive(ProtoBuf, Default)]
pub struct AddWorkspaceUserPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub workspace_id: String,
}

#[derive(ProtoBuf, Default)]
pub struct RemoveWorkspaceUserPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub workspace_id: String,
}

#[derive(ProtoBuf, Default, Clone)]
pub struct RepeatedHistoricalUserPB {
  #[pb(index = 1)]
  pub items: Vec<HistoricalUserPB>,
}

#[derive(ProtoBuf, Default, Clone)]
pub struct HistoricalUserPB {
  #[pb(index = 1)]
  pub user_id: i64,

  #[pb(index = 2)]
  pub user_name: String,

  #[pb(index = 3)]
  pub last_time: i64,

  #[pb(index = 4)]
  pub auth_type: AuthTypePB,

  #[pb(index = 5)]
  pub device_id: String,
}

impl From<Vec<HistoricalUser>> for RepeatedHistoricalUserPB {
  fn from(historical_users: Vec<HistoricalUser>) -> Self {
    Self {
      items: historical_users
        .into_iter()
        .map(HistoricalUserPB::from)
        .collect(),
    }
  }
}

impl From<HistoricalUser> for HistoricalUserPB {
  fn from(historical_user: HistoricalUser) -> Self {
    Self {
      user_id: historical_user.user_id,
      user_name: historical_user.user_name,
      last_time: historical_user.sign_in_timestamp,
      auth_type: historical_user.auth_type.into(),
      device_id: historical_user.device_id,
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
