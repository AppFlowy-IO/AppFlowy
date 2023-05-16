use std::convert::TryInto;

use serde::{Deserialize, Serialize};

use flowy_derive::ProtoBuf;

use crate::entities::parser::*;
use crate::errors::ErrorCode;

#[derive(ProtoBuf, Default)]
pub struct SignInPayloadPB {
  #[pb(index = 1)]
  pub email: String,

  #[pb(index = 2)]
  pub password: String,

  #[pb(index = 3)]
  pub name: String,
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
    })
  }
}

#[derive(Default, Serialize, Deserialize, Debug)]
pub struct SignInParams {
  pub email: String,
  pub password: String,
  pub name: String,
}

#[derive(Debug, Default, Serialize, Deserialize, Clone)]
pub struct SignInResponse {
  pub user_id: i64,
  pub name: String,
  pub email: String,
  pub token: String,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct SignUpParams {
  pub email: String,
  pub name: String,
  pub password: String,
}

#[derive(Serialize, Deserialize, Debug, Default, Clone)]
pub struct SignUpResponse {
  pub user_id: i64,
  pub name: String,
  pub email: String,
  pub token: String,
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct UserProfile {
  pub id: i64,
  pub email: String,
  pub name: String,
  pub token: String,
  pub icon_url: String,
  pub openai_key: String,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct UpdateUserProfileParams {
  pub id: i64,
  pub name: Option<String>,
  pub email: Option<String>,
  pub password: Option<String>,
  pub icon_url: Option<String>,
  pub openai_key: Option<String>,
}

impl UpdateUserProfileParams {
  pub fn new(id: i64) -> Self {
    Self {
      id,
      name: None,
      email: None,
      password: None,
      icon_url: None,
      openai_key: None,
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
}
