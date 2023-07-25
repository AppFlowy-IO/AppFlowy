use std::sync::Arc;

use postgrest::Postgrest;

use flowy_error::{ErrorCode, FlowyError};
use flowy_user::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use flowy_user::event_map::{UserCredentials, UserService, UserWorkspace};
use flowy_user::services::third_party_params_from_box_any;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::supabase::collab_storage_impls::pooler::USER_TABLE;

pub struct SLSupabaseUserAuthServiceImpl {
  postgrest: Arc<Postgrest>,
}

impl UserService for SLSupabaseUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    FutureResult::new(async move { todo!() })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    todo!()
  }

  fn sign_out(&self, token: Option<String>) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn update_user(
    &self,
    credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_user_profile(
    &self,
    credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, FlowyError> {
    todo!()
  }

  fn get_user_workspaces(&self, uid: i64) -> FutureResult<Vec<UserWorkspace>, FlowyError> {
    todo!()
  }

  fn check_user(&self, credential: UserCredentials) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn add_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn remove_workspace_member(
    &self,
    user_email: String,
    workspace_id: String,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }
}
