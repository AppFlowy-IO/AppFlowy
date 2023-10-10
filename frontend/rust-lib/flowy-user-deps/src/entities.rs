use std::str::FromStr;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_repr::*;
use uuid::Uuid;

pub trait UserAuthResponse {
  fn user_id(&self) -> i64;
  fn user_name(&self) -> &str;
  fn latest_workspace(&self) -> &UserWorkspace;
  fn user_workspaces(&self) -> &[UserWorkspace];
  fn device_id(&self) -> &str;
  fn user_token(&self) -> Option<String>;
  fn user_email(&self) -> Option<String>;
  fn encryption_type(&self) -> EncryptionType;
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct SignInResponse {
  pub user_id: i64,
  pub name: String,
  pub latest_workspace: UserWorkspace,
  pub user_workspaces: Vec<UserWorkspace>,
  pub email: Option<String>,
  pub token: Option<String>,
  pub device_id: String,
  pub encryption_type: EncryptionType,
}

impl UserAuthResponse for SignInResponse {
  fn user_id(&self) -> i64 {
    self.user_id
  }

  fn user_name(&self) -> &str {
    &self.name
  }

  fn latest_workspace(&self) -> &UserWorkspace {
    &self.latest_workspace
  }

  fn user_workspaces(&self) -> &[UserWorkspace] {
    &self.user_workspaces
  }

  fn device_id(&self) -> &str {
    &self.device_id
  }

  fn user_token(&self) -> Option<String> {
    self.token.clone()
  }

  fn user_email(&self) -> Option<String> {
    self.email.clone()
  }

  fn encryption_type(&self) -> EncryptionType {
    self.encryption_type.clone()
  }
}

#[derive(Default, Serialize, Deserialize, Debug)]
pub struct SignInParams {
  pub email: String,
  pub password: String,
  pub name: String,
  pub auth_type: AuthType,
  pub device_id: String,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct SignUpParams {
  pub email: String,
  pub name: String,
  pub password: String,
  pub auth_type: AuthType,
  pub device_id: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct AuthResponse {
  pub user_id: i64,
  pub name: String,
  pub latest_workspace: UserWorkspace,
  pub user_workspaces: Vec<UserWorkspace>,
  pub is_new_user: bool,
  pub email: Option<String>,
  pub token: Option<String>,
  pub device_id: String,
  pub encryption_type: EncryptionType,
}

impl UserAuthResponse for AuthResponse {
  fn user_id(&self) -> i64 {
    self.user_id
  }

  fn user_name(&self) -> &str {
    &self.name
  }

  fn latest_workspace(&self) -> &UserWorkspace {
    &self.latest_workspace
  }

  fn user_workspaces(&self) -> &[UserWorkspace] {
    &self.user_workspaces
  }

  fn device_id(&self) -> &str {
    &self.device_id
  }

  fn user_token(&self) -> Option<String> {
    self.token.clone()
  }

  fn user_email(&self) -> Option<String> {
    self.email.clone()
  }

  fn encryption_type(&self) -> EncryptionType {
    self.encryption_type.clone()
  }
}

#[derive(Clone, Debug)]
pub struct UserCredentials {
  /// Currently, the token is only used when the [AuthType] is AFCloud
  pub token: Option<String>,

  /// The user id
  pub uid: Option<i64>,

  /// The user id
  pub uuid: Option<String>,
}

impl UserCredentials {
  pub fn from_uid(uid: i64) -> Self {
    Self {
      token: None,
      uid: Some(uid),
      uuid: None,
    }
  }

  pub fn from_uuid(uuid: String) -> Self {
    Self {
      token: None,
      uid: None,
      uuid: Some(uuid),
    }
  }

  pub fn new(token: Option<String>, uid: Option<i64>, uuid: Option<String>) -> Self {
    Self { token, uid, uuid }
  }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UserWorkspace {
  pub id: String,
  pub name: String,
  pub created_at: DateTime<Utc>,
  /// The database storage id is used indexing all the database in current workspace.
  #[serde(rename = "database_storage_id")]
  pub database_views_aggregate_id: String,
}

impl UserWorkspace {
  pub fn new(workspace_id: &str, _uid: i64) -> Self {
    Self {
      id: workspace_id.to_string(),
      name: "".to_string(),
      created_at: Utc::now(),
      database_views_aggregate_id: uuid::Uuid::new_v4().to_string(),
    }
  }
}

#[derive(Serialize, Deserialize, Default, Debug, Clone)]
pub struct UserProfile {
  #[serde(rename = "id")]
  pub uid: i64,
  pub email: String,
  pub name: String,
  pub token: String,
  pub icon_url: String,
  pub openai_key: String,
  pub stability_ai_key: String,
  pub workspace_id: String,
  pub auth_type: AuthType,
  // If the encryption_sign is not empty, which means the user has enabled the encryption.
  pub encryption_type: EncryptionType,
}

#[derive(Serialize, Deserialize, Debug, Clone, Default, Eq, PartialEq)]
pub enum EncryptionType {
  #[default]
  NoEncryption,
  SelfEncryption(String),
}

impl EncryptionType {
  pub fn from_sign(sign: &str) -> Self {
    if sign.is_empty() {
      EncryptionType::NoEncryption
    } else {
      EncryptionType::SelfEncryption(sign.to_owned())
    }
  }

  pub fn is_need_encrypt_secret(&self) -> bool {
    match self {
      EncryptionType::NoEncryption => false,
      EncryptionType::SelfEncryption(sign) => !sign.is_empty(),
    }
  }

  pub fn sign(&self) -> String {
    match self {
      EncryptionType::NoEncryption => "".to_owned(),
      EncryptionType::SelfEncryption(sign) => sign.to_owned(),
    }
  }
}

impl FromStr for EncryptionType {
  type Err = serde_json::Error;

  fn from_str(s: &str) -> Result<Self, Self::Err> {
    serde_json::from_str(s)
  }
}

impl<T> From<(&T, &AuthType)> for UserProfile
where
  T: UserAuthResponse,
{
  fn from(params: (&T, &AuthType)) -> Self {
    let (value, auth_type) = params;
    Self {
      uid: value.user_id(),
      email: value.user_email().unwrap_or_default(),
      name: value.user_name().to_owned(),
      token: value.user_token().unwrap_or_default(),
      icon_url: "".to_owned(),
      openai_key: "".to_owned(),
      workspace_id: value.latest_workspace().id.to_owned(),
      auth_type: auth_type.clone(),
      encryption_type: value.encryption_type(),
      stability_ai_key: "".to_owned(),
    }
  }
}

#[derive(Serialize, Deserialize, Default, Clone, Debug)]
pub struct UpdateUserProfileParams {
  pub uid: i64,
  pub name: Option<String>,
  pub email: Option<String>,
  pub password: Option<String>,
  pub icon_url: Option<String>,
  pub openai_key: Option<String>,
  pub stability_ai_key: Option<String>,
  pub encryption_sign: Option<String>,
  pub token: Option<String>,
}

impl UpdateUserProfileParams {
  pub fn new(uid: i64) -> Self {
    Self {
      uid,
      ..Default::default()
    }
  }

  pub fn with_token(mut self, token: String) -> Self {
    self.token = Some(token);
    self
  }

  pub fn with_name<T: ToString>(mut self, name: T) -> Self {
    self.name = Some(name.to_string());
    self
  }

  pub fn with_email<T: ToString>(mut self, email: T) -> Self {
    self.email = Some(email.to_string());
    self
  }

  pub fn with_password<T: ToString>(mut self, password: T) -> Self {
    self.password = Some(password.to_string());
    self
  }

  pub fn with_icon_url<T: ToString>(mut self, icon_url: T) -> Self {
    self.icon_url = Some(icon_url.to_string());
    self
  }

  pub fn with_openai_key(mut self, openai_key: &str) -> Self {
    self.openai_key = Some(openai_key.to_owned());
    self
  }

  pub fn with_stability_ai_key(mut self, stability_ai_key: &str) -> Self {
    self.stability_ai_key = Some(stability_ai_key.to_owned());
    self
  }

  pub fn with_encryption_type(mut self, encryption_type: EncryptionType) -> Self {
    let sign = match encryption_type {
      EncryptionType::NoEncryption => "".to_string(),
      EncryptionType::SelfEncryption(sign) => sign,
    };
    self.encryption_sign = Some(sign);
    self
  }

  pub fn is_empty(&self) -> bool {
    self.name.is_none()
      && self.email.is_none()
      && self.password.is_none()
      && self.icon_url.is_none()
      && self.openai_key.is_none()
      && self.encryption_sign.is_none()
      && self.stability_ai_key.is_none()
  }
}

#[derive(Debug, Clone, Hash, Serialize_repr, Deserialize_repr, Eq, PartialEq)]
#[repr(u8)]
pub enum AuthType {
  /// It's a local server, we do fake sign in default.
  Local = 0,
  /// Currently not supported. It will be supported in the future when the
  /// [AppFlowy-Server](https://github.com/AppFlowy-IO/AppFlowy-Server) ready.
  AFCloud = 1,
  /// It uses Supabase as the backend.
  Supabase = 2,
}

impl Default for AuthType {
  fn default() -> Self {
    Self::Local
  }
}

impl AuthType {
  pub fn is_local(&self) -> bool {
    matches!(self, AuthType::Local)
  }
}

impl From<i32> for AuthType {
  fn from(value: i32) -> Self {
    match value {
      0 => AuthType::Local,
      1 => AuthType::AFCloud,
      2 => AuthType::Supabase,
      _ => AuthType::Local,
    }
  }
}
pub struct SupabaseOAuthParams {
  pub uuid: Uuid,
  pub email: String,
  pub device_id: String,
}

pub struct AFCloudOAuthParams {
  pub sign_in_url: String,
  pub device_id: String,
}

#[derive(Clone, Debug)]
pub enum UserTokenState {
  Refresh { token: String },
  Invalid,
}
