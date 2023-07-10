use std::convert::TryInto;

use flowy_derive::ProtoBuf;

use crate::entities::parser::{UserEmail, UserIcon, UserName, UserOpenaiKey, UserDateFormat, UserTimeFormat, UserPassword};
use crate::entities::{AuthTypePB, UpdateUserProfileParams, UserProfile};
use crate::errors::ErrorCode;

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

#[derive(ProtoBuf, Default, Debug, PartialEq, Eq, Clone)]
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
  pub date_format: String,

  #[pb(index = 8)]
  pub time_format: String,
}

impl std::convert::From<UserProfile> for UserProfilePB {
  fn from(user_profile: UserProfile) -> Self {
    Self {
      id: user_profile.id,
      email: user_profile.email,
      name: user_profile.name,
      token: user_profile.token,
      icon_url: user_profile.icon_url,
      openai_key: user_profile.openai_key,
      date_format: user_profile.date_format,
      time_format: user_profile.time_format,
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
  pub date_format: Option<String>,

  #[pb(index = 8, one_of)]
  pub time_format: Option<String>,

  #[pb(index = 9)]
  pub auth_type: AuthTypePB,

  
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

  pub fn date_format(mut self, date_format: &str) -> Self {
    self.date_format = Some(date_format.to_owned());
    self
  }

  pub fn time_format(mut self, time_format: &str) -> Self {
    self.time_format = Some(time_format.to_owned());
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


    let date_format = match self.date_format {
      None => None,
      Some(date_format) => Some(UserDateFormat::parse(date_format)?.0),
    };


    let time_format = match self.time_format {
      None => None,
      Some(time_format) => Some(UserTimeFormat::parse(time_format)?.0),
    };


    Ok(UpdateUserProfileParams {
      id: self.id,
      auth_type: self.auth_type.into(),
      name,
      email,
      password,
      icon_url,
      openai_key,
      date_format,
      time_format,
    })
  }
}
