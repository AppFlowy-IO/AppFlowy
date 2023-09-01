use anyhow::Error;
use collab_plugins::cloud_storage::CollabObject;

use flowy_error::{ErrorCode, FlowyError};
use flowy_user_deps::cloud::UserCloudService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::af_cloud::configuration::{AFCloudConfiguration, HEADER_TOKEN};
use crate::request::HttpRequestBuilder;

pub(crate) struct AFCloudUserAuthServiceImpl {
  config: AFCloudConfiguration,
}

impl AFCloudUserAuthServiceImpl {
  pub(crate) fn new(config: AFCloudConfiguration) -> Self {
    Self { config }
  }
}

impl UserCloudService for AFCloudUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, Error> {
    let url = self.config.sign_up_url();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let resp = user_sign_up_request(params, &url).await?;
      Ok(resp)
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, Error> {
    let url = self.config.sign_in_url();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignInParams>()?;
      let resp = user_sign_in_request(params, &url).await?;
      Ok(resp)
    })
  }

  fn sign_out(&self, token: Option<String>) -> FutureResult<(), Error> {
    match token {
      None => FutureResult::new(async {
        Err(FlowyError::new(ErrorCode::InvalidParams, "Token should not be empty").into())
      }),
      Some(token) => {
        let token = token;
        let url = self.config.sign_out_url();
        FutureResult::new(async move {
          let _ = user_sign_out_request(&token, &url).await;
          Ok(())
        })
      },
    }
  }

  fn update_user(
    &self,
    credential: UserCredentials,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), Error> {
    match credential.token {
      None => FutureResult::new(async {
        Err(FlowyError::new(ErrorCode::InvalidParams, "Token should not be empty").into())
      }),
      Some(token) => {
        let token = token;
        let url = self.config.user_profile_url();
        FutureResult::new(async move {
          update_user_profile_request(&token, params, &url).await?;
          Ok(())
        })
      },
    }
  }

  fn get_user_profile(
    &self,
    credential: UserCredentials,
  ) -> FutureResult<Option<UserProfile>, Error> {
    let url = self.config.user_profile_url();
    FutureResult::new(async move {
      match credential.token {
        None => {
          Err(FlowyError::new(ErrorCode::UnexpectedEmpty, "Token should not be empty").into())
        },
        Some(token) => {
          let profile = get_user_profile_request(&token, &url).await?;
          Ok(Some(profile))
        },
      }
    })
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
  params: SignUpParams,
  url: &str,
) -> Result<SignUpResponse, FlowyError> {
  let response = request_builder().post(url).json(params)?.response().await?;
  Ok(response)
}

pub async fn user_sign_in_request(
  params: SignInParams,
  url: &str,
) -> Result<SignInResponse, FlowyError> {
  let response = request_builder().post(url).json(params)?.response().await?;
  Ok(response)
}

pub async fn user_sign_out_request(token: &str, url: &str) -> Result<(), FlowyError> {
  request_builder()
    .delete(url)
    .header(HEADER_TOKEN, token)
    .send()
    .await?;
  Ok(())
}

pub async fn get_user_profile_request(token: &str, url: &str) -> Result<UserProfile, FlowyError> {
  let user_profile = request_builder()
    .get(url)
    .header(HEADER_TOKEN, token)
    .response()
    .await?;
  Ok(user_profile)
}

pub async fn update_user_profile_request(
  token: &str,
  params: UpdateUserProfileParams,
  url: &str,
) -> Result<(), FlowyError> {
  request_builder()
    .patch(url)
    .header(HEADER_TOKEN, token)
    .json(params)?
    .send()
    .await?;
  Ok(())
}

fn request_builder() -> HttpRequestBuilder {
  HttpRequestBuilder::new()
}
