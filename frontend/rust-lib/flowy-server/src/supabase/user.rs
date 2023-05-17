use postgrest::Postgrest;

use flowy_error::FlowyError;
use flowy_user::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use flowy_user::event_map::UserCloudService;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

struct PostgrestServer {
  postgres: Postgrest,
}

impl PostgrestServer {
  pub fn new(postgres: Postgrest) -> Self {
    Self { postgres }
  }
}

impl UserCloudService for PostgrestServer {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    todo!()
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    todo!()
  }

  fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn update_user(
    &self,
    token: &str,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_user(&self, token: &str) -> FutureResult<UserProfile, FlowyError> {
    todo!()
  }
}
