use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use std::str::FromStr;

use anyhow::Error;
use collab_entity::CollabObject;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

use flowy_error::{ErrorCode, FlowyError};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::entities::{
  AuthResponse, UpdateUserProfileParams, UserCredentials, UserProfile, UserWorkspace,
};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserCloudConfig {
  pub enable_sync: bool,
  enable_encrypt: bool,
  // The secret used to encrypt the user's data
  pub encrypt_secret: String,
}

impl UserCloudConfig {
  pub fn new(encrypt_secret: String) -> Self {
    Self {
      enable_sync: true,
      enable_encrypt: false,
      encrypt_secret,
    }
  }

  pub fn enable_encrypt(&self) -> bool {
    self.enable_encrypt
  }

  pub fn with_enable_encrypt(mut self, enable_encrypt: bool) -> Self {
    self.enable_encrypt = enable_encrypt;
    // When the enable_encrypt is true, the encrypt_secret should not be empty
    debug_assert!(!self.encrypt_secret.is_empty());
    self
  }
}

impl Display for UserCloudConfig {
  fn fmt(&self, f: &mut Formatter<'_>) -> std::fmt::Result {
    write!(
      f,
      "enable_sync: {}, enable_encrypt: {}",
      self.enable_sync, self.enable_encrypt
    )
  }
}

/// Provide the generic interface for the user cloud service
/// The user cloud service is responsible for the user authentication and user profile management
pub trait UserCloudService: Send + Sync + 'static {
  /// Sign up a new account.
  /// The type of the params is defined the this trait's implementation.
  /// Use the `unbox_or_error` of the [BoxAny] to get the params.
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, Error>;

  /// Sign in an account
  /// The type of the params is defined the this trait's implementation.
  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, Error>;

  /// Sign out an account
  fn sign_out(&self, token: Option<String>) -> FutureResult<(), Error>;

  /// Generate a sign in url for the user with the given email
  fn generate_sign_in_url_with_email(&self, email: &str) -> FutureResult<String, Error>;

  /// When the user opens the OAuth URL, it redirects to the corresponding provider's OAuth web page.
  /// After the user is authenticated, the browser will open a deep link to the AppFlowy app (iOS, macOS, etc.),
  /// which will call [Client::sign_in_with_url] to sign in.
  ///
  /// For example, the OAuth URL on Google looks like `https://appflowy.io/authorize?provider=google`.
  fn generate_oauth_url_with_provider(&self, provider: &str) -> FutureResult<String, Error>;

  /// Using the user's token to update the user information
  fn update_user(
    &self,
    credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error>;

  /// Get the user information using the user's token or uid
  /// return None if the user is not found
  fn get_user_profile(
    &self,
    credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error>;

  /// Return the all the workspaces of the user  
  fn get_user_workspaces(&self, uid: i64) -> FutureResult<Vec<UserWorkspace>, Error>;

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), Error>;

  fn add_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), Error>;

  fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), Error>;

  fn get_user_awareness_updates(&self, uid: i64) -> FutureResult<Vec<Vec<u8>>, Error>;

  fn receive_realtime_event(&self, _json: Value) {}

  fn subscribe_user_update(&self) -> Option<UserUpdateReceiver> {
    None
  }

  fn reset_workspace(&self, collab_object: CollabObject) -> FutureResult<(), Error>;

  fn create_collab_object(
    &self,
    collab_object: &CollabObject,
    data: Vec<u8>,
  ) -> FutureResult<(), Error>;
}

pub type UserUpdateReceiver = tokio::sync::broadcast::Receiver<UserUpdate>;
pub type UserUpdateSender = tokio::sync::broadcast::Sender<UserUpdate>;
#[derive(Debug, Clone)]
pub struct UserUpdate {
  pub uid: i64,
  pub name: String,
  pub email: String,
  pub encryption_sign: String,
}

pub fn uuid_from_map(map: &HashMap<String, String>) -> Result<Uuid, Error> {
  let uuid = map
    .get("uuid")
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing uuid field"))?
    .as_str();
  let uuid = Uuid::from_str(uuid)?;
  Ok(uuid)
}
