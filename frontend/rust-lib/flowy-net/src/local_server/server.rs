use lazy_static::lazy_static;
use parking_lot::{Mutex, RwLock};
use tokio::sync::mpsc;

use flowy_error::FlowyError;
use flowy_user::entities::{
  SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams,
  UserProfilePB,
};
use flowy_user::event_map::UserCloudService;
use flowy_user::uid::UserIDGenerator;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

lazy_static! {
  static ref ID_GEN: Mutex<UserIDGenerator> = Mutex::new(UserIDGenerator::new(1));
}

#[derive(Default)]
pub struct LocalServer {
  stop_tx: RwLock<Option<mpsc::Sender<()>>>,
}

impl LocalServer {
  pub fn new() -> Self {
    Self::default()
  }

  pub async fn stop(&self) {
    let sender = self.stop_tx.read().clone();
    if let Some(stop_tx) = sender {
      let _ = stop_tx.send(()).await;
    }
  }
}

impl UserCloudService for LocalServer {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let uid = ID_GEN.lock().next_id();
      Ok(SignUpResponse {
        user_id: uid,
        name: params.name,
        email: params.email,
        token: "".to_string(),
      })
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    FutureResult::new(async move {
      let uid = ID_GEN.lock().next_id();
      let params = params.unbox_or_error::<SignInParams>()?;
      Ok(SignInResponse {
        user_id: uid,
        name: params.name,
        email: params.email,
        token: "".to_string(),
      })
    })
  }

  fn sign_out(&self, _token: &str) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn update_user(
    &self,
    _token: &str,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    FutureResult::new(async { Ok(()) })
  }

  fn get_user(&self, _token: &str) -> FutureResult<UserProfilePB, FlowyError> {
    FutureResult::new(async { Ok(UserProfilePB::default()) })
  }
}
