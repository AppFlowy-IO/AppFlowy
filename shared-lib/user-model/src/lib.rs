pub mod errors;
pub mod parser;

pub use parser::*;

use serde::{Deserialize, Serialize};

#[derive(Default, Serialize, Deserialize, Debug)]
pub struct SignInParams {
  pub email: String,
  pub password: String,
  pub name: String,
}

#[derive(Debug, Default, Serialize, Deserialize, Clone)]
pub struct SignInResponse {
  pub user_id: String,
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
  pub user_id: String,
  pub name: String,
  pub email: String,
  pub token: String,
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct UserProfile {
  pub id: String,
  pub email: String,
  pub name: String,
  pub token: String,
  pub icon_url: String,
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct UpdateUserProfileParams {
  pub id: String,
  pub name: Option<String>,
  pub email: Option<String>,
  pub password: Option<String>,
  pub icon_url: Option<String>,
}

impl UpdateUserProfileParams {
  pub fn new(user_id: &str) -> Self {
    Self {
      id: user_id.to_owned(),
      name: None,
      email: None,
      password: None,
      icon_url: None,
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
