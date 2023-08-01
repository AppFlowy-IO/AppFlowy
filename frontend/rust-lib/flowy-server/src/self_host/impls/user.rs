use anyhow::Error;
use flowy_error::{ErrorCode, FlowyError};
use flowy_user_deps::cloud::UserService;
use flowy_user_deps::entities::*;
use lib_infra::box_any::BoxAny;
use lib_infra::future::FutureResult;

use crate::request::HttpRequestBuilder;
use crate::self_host::configuration::{SelfHostedConfiguration, HEADER_TOKEN};

pub(crate) struct SelfHostedUserAuthServiceImpl {
  config: SelfHostedConfiguration,
}

impl SelfHostedUserAuthServiceImpl {
  pub(crate) fn new(config: SelfHostedConfiguration) -> Self {
    Self { config }
  }
}

impl UserService for SelfHostedUserAuthServiceImpl {
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
