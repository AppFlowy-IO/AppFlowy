use std::convert::TryInto;
use std::str::FromStr;
use validator::Validate;

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};
use flowy_user_pub::entities::*;

use crate::entities::parser::{UserEmail, UserIcon, UserName, UserOpenaiKey, UserPassword};
use crate::entities::{AIModelPB, AuthenticatorPB};
use crate::errors::ErrorCode;

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
  pub authenticator: AuthenticatorPB,

  #[pb(index = 8)]
  pub encryption_sign: String,

  #[pb(index = 9)]
  pub encryption_type: EncryptionTypePB,

  #[pb(index = 10)]
  pub workspace_id: String,

  #[pb(index = 11)]
  pub stability_ai_key: String,

  #[pb(index = 12)]
  pub ai_model: AIModelPB,
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
      authenticator: user_profile.authenticator.into(),
      encryption_sign,
      encryption_type: encryption_ty,
      workspace_id: user_profile.workspace_id,
      stability_ai_key: user_profile.stability_ai_key,
      ai_model: AIModelPB::from_str(&user_profile.ai_model).unwrap_or_default(),
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
      ai_model: None,
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

#[derive(ProtoBuf, Default, Debug, Clone, Validate)]
pub struct UserWorkspacePB {
  #[pb(index = 1)]
  #[validate(custom = "lib_infra::validator_fn::required_not_empty_str")]
  pub workspace_id: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub created_at_timestamp: i64,

  #[pb(index = 4)]
  pub icon: String,
}

impl From<UserWorkspace> for UserWorkspacePB {
  fn from(value: UserWorkspace) -> Self {
    Self {
      workspace_id: value.id,
      name: value.name,
      created_at_timestamp: value.created_at.timestamp(),
      icon: value.icon,
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
