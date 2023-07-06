use lazy_static::lazy_static;
use parking_lot::Mutex;

use flowy_error::FlowyError;
use flowy_user::entities::{
  SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams, UserProfile,
};
use flowy_user::event_map::{UserAuthService, UserCredentials};
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::local_server::uid::UserIDGenerator;

lazy_static! {
  static ref ID_GEN: Mutex<UserIDGenerator> = Mutex::new(UserIDGenerator::new(1));
}

pub(crate) struct LocalServerUserAuthServiceImpl();

impl UserAuthService for LocalServerUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let uid = ID_GEN.lock().next_id();
      let workspace_id = uuid::Uuid::new_v4().to_string();
      Ok(SignUpResponse {
        user_id: uid,
        name: params.name,
        workspace_id,
        is_new: true,
        email: Some(params.email),
        token: None,
      })
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    FutureResult::new(async move {
      let uid = ID_GEN.lock().next_id();
      let params = params.unbox_or_error::<SignInParams>()?;
      let workspace_id = uuid::Uuid::new_v4().to_string();
      Ok(SignInResponse {
        user_id: uid,
        name: params.name,
        workspace_id,
        email: Some(params.email),
        token: None,
      })
    })
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, FlowyError> {
    FutureResult::new(async { Ok(None) })
  }

  fn check_user(&self, _credential: UserCredentials) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }
}
