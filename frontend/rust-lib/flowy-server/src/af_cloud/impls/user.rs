use std::sync::Arc;

use anyhow::Error;
use collab_define::CollabObject;
use tokio::sync::Mutex;

use flowy_error::{ErrorCode, FlowyError};
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::af_cloud::configuration::AFCloudConfiguration;

pub(crate) struct AFCloudUserAuthServiceImpl {
  config: AFCloudConfiguration,
  client: Arc<Mutex<client_api::Client>>,
}

impl AFCloudUserAuthServiceImpl {
  pub(crate) fn new(config: AFCloudConfiguration, client: client_api::Client) -> Self {
    let client = Arc::new(Mutex::new(client));
    Self { config, client }
  }
}

impl UserCloudService for AFCloudUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    let c = self.client.clone();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let resp = user_sign_up_request(c, params).await?;
      Ok(resp)
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, Error> {
    todo!()
  }

  fn sign_out(&self, token: Option<String>) -> FutureResult<(), Error> {
    todo!()
  }

  fn update_user(
    &self,
    credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error> {
    todo!()
  }

  fn get_user_profile(
    &self,
    credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    todo!()
  }

  fn get_user_workspaces(
    &self,
    _uid: i64,
  ) -> FutureResult<std::vec::Vec<flowy_user_deps::entities::UserWorkspace>, Error> {
    // TODO(nathan): implement the RESTful API for this
    todo!()
  }

  fn check_user(&self, _credential: UserCredentials) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
  }

  fn add_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
  }

  fn remove_workspace_member(
    &self,
    _user_email: String,
    _workspace_id: String,
  ) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
  }

  fn get_user_awareness_updates(&self, _uid: i64) -> FutureResult<Vec<Vec<u8>>, Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(vec![]) })
  }

  fn reset_workspace(&self, _collab_object: CollabObject) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
  }

  fn create_collab_object(
    &self,
    _collab_object: &CollabObject,
    _data: Vec<u8>,
  ) -> FutureResult<(), Error> {
    // TODO(nathan): implement the RESTful API for this
    FutureResult::new(async { Ok(()) })
  }
}

pub async fn user_sign_up_request(
  client: Arc<Mutex<client_api::Client>>,
  params: SignUpParams,
) -> Result<SignUpResponse, FlowyError> {
  let mut client = client.try_lock().map_err(|e| {
    FlowyError::new(
      ErrorCode::UnexpectedEmpty,
      format!("Client is not available: {}", e),
    )
  })?;

  let user = client.sign_up(&params.email, &params.password).await?;
  todo!()
  // tracing::info!("User signed up: {:?}", user);
  // match user.confirmed_at {
  //   Some(_) => {
  //       // User is already confirmed, help her/him to sign in
  //       let token = client.sign_in_password(&params.email, &params.password).await?;
  //
  //       // TODO:
  //       // Query workspace list
  //       // Query user profile
  //
  //       todo!()
  //   },
  //   None => Err(FlowyError::new(
  //     ErrorCode::AwaitingEmailConfirmation,
  //     "Awaiting email confirmation".to_string(),
  //   )),
  // }
}
