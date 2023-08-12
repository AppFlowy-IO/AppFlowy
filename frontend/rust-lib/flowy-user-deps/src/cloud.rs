use std::collections::HashMap;
use std::str::FromStr;

use anyhow::Error;
use uuid::Uuid;

use flowy_error::{ErrorCode, FlowyError};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::entities::{
  SignInResponse, SignUpResponse, ThirdPartyParams, UpdateUserProfileParams, UserCredentials,
  UserProfile, UserWorkspace,
};

/// Provide the generic interface for the user cloud service
/// The user cloud service is responsible for the user authentication and user profile management
pub trait UserService: Send + Sync {
  /// Sign up a new account.
  /// The type of the params is defined the this trait's implementation.
  /// Use the `unbox_or_error` of the [BoxAny] to get the params.
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error>;

  /// Sign in an account
  /// The type of the params is defined the this trait's implementation.
  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, Error>;

  /// Sign out an account
  fn sign_out(&self, token: Option<String>) -> FutureResult<(), Error>;

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
}

pub fn third_party_params_from_box_any(any: BoxAny) -> Result<ThirdPartyParams, Error> {
  let map: HashMap<String, String> = any.unbox_or_error()?;
  let uuid = uuid_from_map(&map)?;
  let email = map.get("email").cloned().unwrap_or_default();
  let device_id = map.get("device_id").cloned().unwrap_or_default();
  Ok(ThirdPartyParams {
    uuid,
    email,
    device_id,
  })
}

pub fn uuid_from_map(map: &HashMap<String, String>) -> Result<Uuid, Error> {
  let uuid = map
    .get("uuid")
    .ok_or_else(|| FlowyError::new(ErrorCode::MissingAuthField, "Missing uuid field"))?
    .as_str();
  let uuid = Uuid::from_str(uuid)?;
  Ok(uuid)
}
