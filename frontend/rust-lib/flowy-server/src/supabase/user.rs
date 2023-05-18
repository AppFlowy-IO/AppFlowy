use std::sync::Arc;

use postgrest::Postgrest;

use flowy_error::FlowyError;
use flowy_user::entities::{SignInResponse, SignUpResponse, UpdateUserProfileParams, UserProfile};
use flowy_user::event_map::UserAuthService;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

pub(crate) struct PostgrestUserAuthServiceImpl {
  postgrest: Arc<Postgrest>,
}

impl PostgrestUserAuthServiceImpl {
  pub(crate) fn new(postgrest: Arc<Postgrest>) -> Self {
    Self { postgrest }
  }
}

impl UserAuthService for PostgrestUserAuthServiceImpl {
  fn sign_up(&self, _params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    todo!()
  }

  fn sign_in(&self, _params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    todo!()
  }

  fn sign_out(&self, _token: &str) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn update_user(
    &self,
    _token: &str,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    todo!()
  }

  fn get_user(&self, _token: &str) -> FutureResult<UserProfile, FlowyError> {
    todo!()
  }
}
