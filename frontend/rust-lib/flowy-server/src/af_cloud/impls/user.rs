use std::sync::Arc;

use anyhow::Error;
use collab_define::CollabObject;

use flowy_error::FlowyError;
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::af_cloud::{AFCloudClient, AFServer};

pub(crate) struct AFCloudUserAuthServiceImpl<T> {
  server: T,
}

impl<T> AFCloudUserAuthServiceImpl<T> {
  pub(crate) fn new(server: T) -> Self {
    Self { server }
  }
}

impl<T> UserCloudService for AFCloudUserAuthServiceImpl<T>
where
  T: AFServer,
{
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    let try_get_client = self.server.try_get_client();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let resp = user_sign_up_request(try_get_client?, params).await?;
      Ok(resp)
    })
  }

  fn sign_in(&self, _params: BoxAny) -> FutureResult<SignInResponse, Error> {
    todo!()
  }

  fn sign_out(&self, _token: Option<String>) -> FutureResult<(), Error> {
    todo!()
  }

  fn update_user(
    &self,
    _credential: UserCredentials,
    _params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error> {
    todo!()
  }

  fn get_user_profile(
    &self,
    _credential: UserCredentials,
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
  client: Arc<AFCloudClient>,
  params: SignUpParams,
) -> Result<SignUpResponse, FlowyError> {
  client
    .read()
    .await
    .sign_up(&params.email, &params.password)
    .await?;
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
