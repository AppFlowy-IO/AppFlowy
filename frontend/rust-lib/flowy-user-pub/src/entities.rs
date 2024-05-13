use std::str::FromStr;

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use serde_repr::*;
use uuid::Uuid;

pub const USER_METADATA_OPEN_AI_KEY: &str = "openai_key";
pub const USER_METADATA_STABILITY_AI_KEY: &str = "stability_ai_key";
pub const USER_METADATA_ICON_URL: &str = "icon_url";
pub const USER_METADATA_UPDATE_AT: &str = "updated_at";

pub trait UserAuthResponse {
  fn user_id(&self) -> i64;
  fn user_uuid(&self) -> &Uuid;
  fn user_name(&self) -> &str;
  fn latest_workspace(&self) -> &UserWorkspace;
  fn user_workspaces(&self) -> &[UserWorkspace];
  fn user_token(&self) -> Option<String>;
  fn user_email(&self) -> Option<String>;
  fn encryption_type(&self) -> EncryptionType;
  fn metadata(&self) -> &Option<serde_json::Value>;
  fn updated_at(&self) -> i64;
}

#[derive(Default, Serialize, Deserialize, Debug)]
pub struct SignInParams {
  pub email: String,
  pub password: String,
  pub name: String,
  pub auth_type: Authenticator,
}

#[derive(Serialize, Deserialize, Default, Debug)]
pub struct SignUpParams {
  pub email: String,
  pub name: String,
  pub password: String,
  pub auth_type: Authenticator,
  pub device_id: String,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct AuthResponse {
  pub user_id: i64,
  pub user_uuid: Uuid,
  pub name: String,
  pub latest_workspace: UserWorkspace,
  pub user_workspaces: Vec<UserWorkspace>,
  pub is_new_user: bool,
  pub email: Option<String>,
  pub token: Option<String>,
  pub encryption_type: EncryptionType,
  pub updated_at: i64,
  pub metadata: Option<serde_json::Value>,
}

impl UserAuthResponse for AuthResponse {
  fn user_id(&self) -> i64 {
    self.user_id
  }

  fn user_uuid(&self) -> &Uuid {
    &self.user_uuid
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

  fn user_token(&self) -> Option<String> {
    self.token.clone()
  }

  fn user_email(&self) -> Option<String> {
    self.email.clone()
  }

  fn encryption_type(&self) -> EncryptionType {
    self.encryption_type.clone()
  }

  fn metadata(&self) -> &Option<Value> {
    &self.metadata
  }

  fn updated_at(&self) -> i64 {
    self.updated_at
  }
}

#[derive(Clone, Debug)]
pub struct UserCredentials {
  /// Currently, the token is only used when the [Authenticator] is AppFlowyCloud
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
  /// The database storage id is used indexing all the database views in current workspace.
  #[serde(rename = "database_storage_id")]
  pub database_indexer_id: String,
  #[serde(default)]
  pub icon: String,
}

impl UserWorkspace {
  pub fn new(workspace_id: &str, _uid: i64) -> Self {
    Self {
      id: workspace_id.to_string(),
      name: "".to_string(),
      created_at: Utc::now(),
      database_indexer_id: Uuid::new_v4().to_string(),
      icon: "".to_string(),
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
  pub authenticator: Authenticator,
  // If the encryption_sign is not empty, which means the user has enabled the encryption.
  pub encryption_type: EncryptionType,
  pub updated_at: i64,
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

  pub fn require_encrypt_secret(&self) -> bool {
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

impl<T> From<(&T, &Authenticator)> for UserProfile
where
  T: UserAuthResponse,
{
  fn from(params: (&T, &Authenticator)) -> Self {
    let (value, auth_type) = params;
    let (icon_url, openai_key, stability_ai_key) = {
      value
        .metadata()
        .as_ref()
        .map(|m| {
          (
            m.get(USER_METADATA_ICON_URL)
              .map(|v| v.as_str().map(|s| s.to_string()).unwrap_or_default())
              .unwrap_or_default(),
            m.get(USER_METADATA_OPEN_AI_KEY)
              .map(|v| v.as_str().map(|s| s.to_string()).unwrap_or_default())
              .unwrap_or_default(),
            m.get(USER_METADATA_STABILITY_AI_KEY)
              .map(|v| v.as_str().map(|s| s.to_string()).unwrap_or_default())
              .unwrap_or_default(),
          )
        })
        .unwrap_or_default()
    };
    Self {
      uid: value.user_id(),
      email: value.user_email().unwrap_or_default(),
      name: value.user_name().to_owned(),
      token: value.user_token().unwrap_or_default(),
      icon_url,
      openai_key,
      workspace_id: value.latest_workspace().id.to_owned(),
      authenticator: auth_type.clone(),
      encryption_type: value.encryption_type(),
      stability_ai_key,
      updated_at: value.updated_at(),
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
pub enum Authenticator {
  /// It's a local server, we do fake sign in default.
  Local = 0,
  /// Currently not supported. It will be supported in the future when the
  /// [AppFlowy-Server](https://github.com/AppFlowy-IO/AppFlowy-Server) ready.
  AppFlowyCloud = 1,
  /// It uses Supabase as the backend.
  Supabase = 2,
}

impl Default for Authenticator {
  fn default() -> Self {
    Self::Local
  }
}

impl Authenticator {
  pub fn is_local(&self) -> bool {
    matches!(self, Authenticator::Local)
  }

  pub fn is_appflowy_cloud(&self) -> bool {
    matches!(self, Authenticator::AppFlowyCloud)
  }
}

impl From<i32> for Authenticator {
  fn from(value: i32) -> Self {
    match value {
      0 => Authenticator::Local,
      1 => Authenticator::AppFlowyCloud,
      2 => Authenticator::Supabase,
      _ => Authenticator::Local,
    }
  }
}
pub struct SupabaseOAuthParams {
  pub uuid: Uuid,
  pub email: String,
}

pub struct AFCloudOAuthParams {
  pub sign_in_url: String,
}

#[derive(Clone, Debug)]
pub enum UserTokenState {
  Init,
  Refresh { token: String },
  Invalid,
}

// Workspace Role
#[derive(Clone, Debug)]
pub enum Role {
  Owner,
  Member,
  Guest,
}

pub struct WorkspaceMember {
  pub email: String,
  pub role: Role,
  pub name: String,
}

/// represent the user awareness object id for the workspace.
pub fn user_awareness_object_id(user_uuid: &Uuid, workspace_id: &str) -> Uuid {
  Uuid::new_v5(
    user_uuid,
    format!("user_awareness:{}", workspace_id).as_bytes(),
  )
}

#[derive(Clone, Debug)]
pub enum WorkspaceInvitationStatus {
  Pending,
  Accepted,
  Rejected,
}

pub struct WorkspaceInvitation {
  pub invite_id: Uuid,
  pub workspace_id: Uuid,
  pub workspace_name: Option<String>,
  pub inviter_email: Option<String>,
  pub inviter_name: Option<String>,
  pub status: WorkspaceInvitationStatus,
  pub updated_at: DateTime<Utc>,
}

pub enum RecurringInterval {
  Month,
  Year,
}

pub enum SubscriptionPlan {
  None,
  Pro,
  Team,
}

pub struct WorkspaceSubscription {
  pub workspace_id: String,
  pub subscription_plan: SubscriptionPlan,
  pub recurring_interval: RecurringInterval,
  pub is_active: bool,
}

pub struct WorkspaceUsage {
  pub member_count: usize,
  pub member_count_limit: usize,
  pub total_blob_bytes: usize,
  pub total_blob_bytes_limit: usize,
}
