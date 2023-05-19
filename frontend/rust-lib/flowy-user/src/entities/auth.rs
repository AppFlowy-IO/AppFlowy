use std::collections::HashMap;
use std::convert::TryInto;

use serde::{Deserialize, Serialize};

use flowy_derive::{ProtoBuf, ProtoBuf_Enum};

use crate::entities::parser::*;
use crate::errors::ErrorCode;
use crate::services::AuthType;

#[derive(ProtoBuf, Default)]
pub struct SignInPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub password: String,

  #[pb(index = 3)]
  pub name: String,

  #[pb(index = 4)]
  pub auth_type: AuthTypePB,
}

impl TryInto<SignInParams> for SignInPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SignInParams, Self::Error> {
    let email = UserEmail::parse(self.email)?;
    let password = UserPassword::parse(self.password)?;

    Ok(SignInParams {
      email: email.0,
      password: password.0,
      name: self.name,
      auth_type: self.auth_type.into(),
    })
  }
}

#[derive(ProtoBuf, Default)]
pub struct SignUpPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub name: String,

  #[pb(index = 3)]
  pub password: String,

  #[pb(index = 4)]
  pub auth_type: AuthTypePB,
}
impl TryInto<SignUpParams> for SignUpPayloadPB {
  type Error = ErrorCode;

  fn try_into(self) -> Result<SignUpParams, Self::Error> {
    let email = UserEmail::parse(self.email)?;
    let password = UserPassword::parse(self.password)?;
    let name = UserName::parse(self.name)?;

    Ok(SignUpParams {
      email: email.0,
      name: name.0,
      password: password.0,
      auth_type: self.auth_type.into(),
    })
  }
}

#[derive(Default, Serialize, Deserialize, Debug)]
pub struct SignInParams {
  pub email: String,
  pub password: String,
  pub name: String,
  pub auth_type: AuthType,
}

#[derive(Debug, Default, Serialize, Deserialize, Clone)]
pub struct SignInResponse {
  pub user_id: i64,
  pub name: String,
  pub workspace_id: String,
  pub email: Option<String>,
  pub token: Option<String>,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct SignUpParams {
  pub email: String,
  pub name: String,
  pub password: String,
  pub auth_type: AuthType,
}

#[derive(Serialize, Deserialize, Debug, Default, Clone)]
pub struct SignUpResponse {
  pub user_id: i64,
  pub name: String,
  pub workspace_id: String,
  pub email: Option<String>,
  pub token: Option<String>,
}

#[derive(ProtoBuf, Default)]
pub struct ThirdPartyAuthPB {
  /// Use this field to store the third party auth information.
  /// Different auth type has different fields.
  /// Supabase:
  ///   - map: { "uuid": "xxx" }
  ///
  #[pb(index = 1)]
  pub map: HashMap<String, String>,

  #[pb(index = 2)]
  pub auth_type: AuthTypePB,
}

#[derive(ProtoBuf_Enum, Debug, Clone)]
pub enum AuthTypePB {
  Local = 0,
  SelfHosted = 1,
  Supabase = 2,
}

impl Default for AuthTypePB {
  fn default() -> Self {
    Self::Local
  }
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct UserProfile {
  pub id: i64,
  pub email: String,
  pub name: String,
  pub token: String,
  pub icon_url: String,
  pub openai_key: String,
  pub workspace_id: String,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct UpdateUserProfileParams {
  pub id: i64,
  pub auth_type: AuthType,
  pub name: Option<String>,
  pub email: Option<String>,
  pub password: Option<String>,
  pub icon_url: Option<String>,
  pub openai_key: Option<String>,
}

impl UpdateUserProfileParams {
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

  pub fn is_empty(&self) -> bool {
    self.name.is_none()
      && self.email.is_none()
      && self.password.is_none()
      && self.icon_url.is_none()
      && self.openai_key.is_none()
  }
}

#[derive(ProtoBuf, Default)]
pub struct SignOutPB {
  #[pb(index = 1)]
  pub auth_type: AuthTypePB,
}
