use crate::{configuration::*, request::HttpRequestBuilder};
use flowy_error::FlowyError;
use flowy_user::entities::{
    SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams, UserProfile,
};
use flowy_user::event_map::UserCloudService;
use http_flowy::errors::ServerError;
use lib_infra::future::FutureResult;

pub struct UserHttpCloudService {
    config: ClientServerConfiguration,
}
impl UserHttpCloudService {
    pub fn new(config: &ClientServerConfiguration) -> Self {
        Self { config: config.clone() }
    }
}

impl UserCloudService for UserHttpCloudService {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> {
        let url = self.config.sign_up_url();
        FutureResult::new(async move {
            let resp = user_sign_up_request(params, &url).await?;
            Ok(resp)
        })
    }

    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> {
        let url = self.config.sign_in_url();
        FutureResult::new(async move {
            let resp = user_sign_in_request(params, &url).await?;
            Ok(resp)
        })
    }

    fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.sign_out_url();
        FutureResult::new(async move {
            let _ = user_sign_out_request(&token, &url).await;
            Ok(())
        })
    }

    fn update_user(&self, token: &str, params: UpdateUserProfileParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        FutureResult::new(async move {
            let _ = update_user_profile_request(&token, params, &url).await?;
            Ok(())
        })
    }

    fn get_user(&self, token: &str) -> FutureResult<UserProfile, FlowyError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        FutureResult::new(async move {
            let profile = get_user_profile_request(&token, &url).await?;
            Ok(profile)
        })
    }

    fn ws_addr(&self) -> String {
        self.config.ws_addr()
    }
}

pub async fn user_sign_up_request(params: SignUpParams, url: &str) -> Result<SignUpResponse, ServerError> {
    let response = request_builder()
        .post(&url.to_owned())
        .protobuf(params)?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_in_request(params: SignInParams, url: &str) -> Result<SignInResponse, ServerError> {
    let response = request_builder()
        .post(&url.to_owned())
        .protobuf(params)?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_out_request(token: &str, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .send()
        .await?;
    Ok(())
}

pub async fn get_user_profile_request(token: &str, url: &str) -> Result<UserProfile, ServerError> {
    let user_profile = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .response()
        .await?;
    Ok(user_profile)
}

pub async fn update_user_profile_request(
    token: &str,
    params: UpdateUserProfileParams,
    url: &str,
) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

fn request_builder() -> HttpRequestBuilder {
    HttpRequestBuilder::new()
}
