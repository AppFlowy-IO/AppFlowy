use std::sync::Arc;

use postgrest::Postgrest;

use flowy_error::FlowyError;
use flowy_user::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use flowy_user::event_map::{UserCredentials, UserService, UserWorkspace};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

pub struct SLSupabaseUserAuthServiceImpl {
  postgrest: Arc<Postgrest>,
}

impl UserService for SLSupabaseUserAuthServiceImpl {
  fn sign_up(&self, _params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    FutureResult::new(async move { todo!() })
  }

  fn sign_in(&self, _params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    todo!()
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, FlowyError> {
    todo!()
  }

  fn get_user_workspaces(&self, _uid: i64) -> FutureResult<Vec<UserWorkspace>, FlowyError> {
    todo!()
  }

  fn check_user(&self, _credential: UserCredentials) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn add_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn remove_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }
}
