use flowy_error::{ErrorCode, FlowyError};
use flowy_user::entities::{
  SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams, UserProfile,
};
use flowy_user::event_map::UserAuthService;
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

impl UserAuthService for SelfHostedUserAuthServiceImpl {
  fn sign_up(&self, params: BoxAny) -> FutureResult<SignUpResponse, FlowyError> {
    let url = self.config.sign_up_url();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignUpParams>()?;
      let resp = user_sign_up_request(params, &url).await?;
      Ok(resp)
    })
  }

  fn sign_in(&self, params: BoxAny) -> FutureResult<SignInResponse, FlowyError> {
    let url = self.config.sign_in_url();
    FutureResult::new(async move {
      let params = params.unbox_or_error::<SignInParams>()?;
      let resp = user_sign_in_request(params, &url).await?;
      Ok(resp)
    })
  }

  fn sign_out(&self, token: Option<String>) -> FutureResult<(), FlowyError> {
    match token {
      None => FutureResult::new(async {
        Err(FlowyError::new(
          ErrorCode::InvalidData,
          "Token should not be empty",
        ))
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
    _uid: i64,
    token: &Option<String>,
    params: UpdateUserProfileParams,
  ) -> FutureResult<(), FlowyError> {
    match token {
      None => FutureResult::new(async {
        Err(FlowyError::new(
          ErrorCode::InvalidData,
          "Token should not be empty",
        ))
      }),
      Some(token) => {
        let token = token.to_owned();
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
    token: Option<String>,
    _uid: i64,
  ) -> FutureResult<Option<UserProfile>, FlowyError> {
    let token = token;
    let url = self.config.user_profile_url();
    FutureResult::new(async move {
      match token {
        None => Err(FlowyError::new(
          ErrorCode::UnexpectedEmpty,
          "Token should not be empty",
        )),
        Some(token) => {
          let profile = get_user_profile_request(&token, &url).await?;
          Ok(Some(profile))
        },
      }
    })
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
