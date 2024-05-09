use collab_entity::{CollabObject, CollabType};
use flowy_error::{internal_error, ErrorCode, FlowyError};
use lib_infra::box_any::BoxAny;
use lib_infra::conditional_send_sync_trait;
use lib_infra::future::FutureResult;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::fmt::{Display, Formatter};
use std::str::FromStr;
use std::sync::Arc;
use tokio_stream::wrappers::WatchStream;
use uuid::Uuid;

use crate::entities::{
  AuthResponse, Authenticator, RecurringInterval, Role, SubscriptionPlan, UpdateUserProfileParams,
  UserCredentials, UserProfile, UserTokenState, UserWorkspace, WorkspaceInvitation,
  WorkspaceInvitationStatus, WorkspaceMember, WorkspaceSubscription,
};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserCloudConfig {
  pub enable_sync: bool,
  pub enable_encrypt: bool,
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

conditional_send_sync_trait! {
  "This trait is intended for implementation by providers that offer cloud-based services for users.
  It includes methods for handling authentication tokens, enabling/disabling synchronization,
  setting network reachability, managing encryption secrets, and accessing user-specific cloud services.";

  UserCloudServiceProvider {
  /// Sets the authentication token for the cloud service.
  ///
  /// # Arguments
  /// * `token`: A string slice representing the authentication token.
  ///
  /// # Returns
  /// A `Result` which is `Ok` if the token is successfully set, or a `FlowyError` otherwise.
  fn set_token(&self, token: &str) -> Result<(), FlowyError>;

  /// Subscribes to the state of the authentication token.
  ///
  /// # Returns
  /// An `Option` containing a `WatchStream<UserTokenState>` if available, or `None` otherwise.
  /// The stream allows the caller to watch for changes in the token state.
  fn subscribe_token_state(&self) -> Option<WatchStream<UserTokenState>>;

  /// Sets the synchronization state for a user.
  ///
  /// # Arguments
  /// * `uid`: An i64 representing the user ID.
  /// * `enable_sync`: A boolean indicating whether synchronization should be enabled or disabled.
  fn set_enable_sync(&self, uid: i64, enable_sync: bool);

  /// Sets the authenticator when user sign in or sign up.
  ///
  /// # Arguments
  /// * `authenticator`: An `Authenticator` object.
  fn set_user_authenticator(&self, authenticator: &Authenticator);

  fn get_user_authenticator(&self) -> Authenticator;

  /// Sets the network reachability
  ///
  /// # Arguments
  /// * `reachable`: A boolean indicating whether the network is reachable.
  fn set_network_reachable(&self, reachable: bool);

  /// Sets the encryption secret for secure communication.
  ///
  /// # Arguments
  /// * `secret`: A `String` representing the encryption secret.
  fn set_encrypt_secret(&self, secret: String);

  /// Retrieves the user-specific cloud service.
  ///
  /// # Returns
  /// A `Result` containing an `Arc<dyn UserCloudService>` if successful, or a `FlowyError` otherwise.
  fn get_user_service(&self) -> Result<Arc<dyn UserCloudService>, FlowyError>;

  /// Retrieves the service URL.
  ///
  /// # Returns
  /// A `String` representing the service URL.
  fn service_url(&self) -> String;
  }
}
/// Provide the generic interface for the user cloud service
/// The user cloud service is responsible for the user authentication and user profile management
#[allow(unused_variables)]
pub trait UserCloudService: Send + Sync + 'static {
  /// Sign up a new account.
  /// The type of the params is defined the this trait's implementation.
  /// Use the `unbox_or_error` of the [BoxAny] to get the params.
  fn sign_up(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError>;

  /// Sign in an account
  /// The type of the params is defined the this trait's implementation.
  fn sign_in(&self, params: BoxAny) -> FutureResult<AuthResponse, FlowyError>;

  /// Sign out an account
  fn sign_out(&self, token: Option<String>) -> FutureResult<(), FlowyError>;

  /// Generate a sign in url for the user with the given email
  /// Currently, only use the admin client for testing
  fn generate_sign_in_url_with_email(&self, email: &str) -> FutureResult<String, FlowyError>;

  fn create_user(&self, email: &str, password: &str) -> FutureResult<(), FlowyError>;

  fn sign_in_with_password(
    &self,
    email: &str,
    password: &str,
  ) -> FutureResult<UserProfile, FlowyError>;

  fn sign_in_with_magic_link(&self, email: &str, redirect_to: &str)
    -> FutureResult<(), FlowyError>;

  /// When the user opens the OAuth URL, it redirects to the corresponding provider's OAuth web page.
  /// After the user is authenticated, the browser will open a deep link to the AppFlowy app (iOS, macOS, etc.),
  /// which will call [Client::sign_in_with_url]generate_sign_in_url_with_email to sign in.
  ///
  /// For example, the OAuth URL on Google looks like `https://appflowy.io/authorize?provider=google`.
  fn generate_oauth_url_with_provider(&self, provider: &str) -> FutureResult<String, FlowyError>;

  /// Using the user's token to update the user information
  fn update_user(
    &self,
    credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError>;

  /// Get the user information using the user's token or uid
  /// return None if the user is not found
  fn get_user_profile(&self, credential: UserCredentials) -> FutureResult<UserProfile, FlowyError>;

  fn open_workspace(&self, workspace_id: &str) -> FutureResult<UserWorkspace, FlowyError>;

  /// Return the all the workspaces of the user
  fn get_all_workspace(&self, uid: i64) -> FutureResult<Vec<UserWorkspace>, FlowyError>;

  /// Creates a new workspace for the user.
  /// Returns the new workspace if successful
  fn create_workspace(&self, workspace_name: &str) -> FutureResult<UserWorkspace, FlowyError>;

  // Updates the workspace name and icon
  fn patch_workspace(
    &self,
    workspace_id: &str,
    new_workspace_name: Option<&str>,
    new_workspace_icon: Option<&str>,
  ) -> FutureResult<(), FlowyError>;

  /// Deletes a workspace owned by the user.
  fn delete_workspace(&self, workspace_id: &str) -> FutureResult<(), FlowyError>;

  // Deprecated, use invite instead
  fn add_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn invite_workspace_member(
    &self,
    invitee_email: String,
    workspace_id: String,
    role: Role,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn list_workspace_invitations(
    &self,
    filter: Option<WorkspaceInvitationStatus>,
  ) -> FutureResult<Vec<WorkspaceInvitation>, FlowyError> {
    FutureResult::new(async { Ok(vec![]) })
  }

  fn accept_workspace_invitations(&self, invite_id: String) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn update_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
    role: Role,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_workspace_members(
    &self,
    workspace_id: String,
  ) -> FutureResult<Vec<WorkspaceMember>, FlowyError> {
    FutureResult::new(async { Ok(vec![]) })
  }

  fn get_user_awareness_doc_state(
    &self,
    uid: i64,
    workspace_id: &str,
    object_id: &str,
  ) -> FutureResult<Vec<u8>, FlowyError>;

  fn receive_realtime_event(&self, _json: Value) {}

  fn subscribe_user_update(&self) -> Option<UserUpdateReceiver> {
    None
  }

  fn reset_workspace(&self, collab_object: CollabObject) -> FutureResult<(), FlowyError>;

  fn create_collab_object(
    &self,
    collab_object: &CollabObject,
    data: Vec<u8>,
  ) -> FutureResult<(), FlowyError>;

  fn batch_create_collab_object(
    &self,
    workspace_id: &str,
    objects: Vec<UserCollabParams>,
  ) -> FutureResult<(), FlowyError>;

  fn leave_workspace(&self, workspace_id: &str) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn subscribe_workspace(
    &self,
    workspace_id: String,
    recurring_interval: RecurringInterval,
    workspace_subscription_plan: SubscriptionPlan,
    success_url: String,
  ) -> FutureResult<String, FlowyError> {
    FutureResult::new(async { Err(FlowyError::not_support()) })
  }

  fn get_workspace_subscriptions(&self) -> FutureResult<Vec<WorkspaceSubscription>, FlowyError> {
    FutureResult::new(async { Err(FlowyError::not_support()) })
  }
}

pub type UserUpdateReceiver = tokio::sync::mpsc::Receiver<UserUpdate>;
pub type UserUpdateSender = tokio::sync::mpsc::Sender<UserUpdate>;
#[derive(Debug, Clone)]
pub struct UserUpdate {
  pub uid: i64,
  pub name: Option<String>,
  pub email: Option<String>,
  pub encryption_sign: String,
}

pub fn uuid_from_map(map: &HashMap<String, String>) -> Result<Uuid, FlowyError> {
  let uuid = map
    .get("uuid")
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing uuid field"))?
    .as_str();
  Uuid::from_str(uuid).map_err(internal_error)
}

#[derive(Debug)]
pub struct UserCollabParams {
  pub object_id: String,
  pub encoded_collab: Vec<u8>,
  pub collab_type: CollabType,
}
