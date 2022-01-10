use backend_service::{configuration::*, errors::ServerError, request::HttpRequestBuilder};
use flowy_error::FlowyError;
use flowy_user_data_model::entities::{
    SignInParams,
    SignInResponse,
    SignUpParams,
    SignUpResponse,
    UpdateUserParams,
    UserProfile,
};
use lib_infra::{future::FutureResult, uuid_string};

pub struct UserHttpCloudService {
    config: ClientServerConfiguration,
}
impl UserHttpCloudService {
    pub fn new(config: &ClientServerConfiguration) -> Self { Self { config: config.clone() } }
}

impl UserHttpCloudService {
    pub fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> {
        let url = self.config.sign_up_url();
        FutureResult::new(async move {
            let resp = user_sign_up_request(params, &url).await?;
            Ok(resp)
        })
    }

    pub fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> {
        let url = self.config.sign_in_url();
        FutureResult::new(async move {
            let resp = user_sign_in_request(params, &url).await?;
            Ok(resp)
        })
    }

    pub fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.sign_out_url();
        FutureResult::new(async move {
            let _ = user_sign_out_request(&token, &url).await;
            Ok(())
        })
    }

    pub fn update_user(&self, token: &str, params: UpdateUserParams) -> FutureResult<(), FlowyError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        FutureResult::new(async move {
            let _ = update_user_profile_request(&token, params, &url).await?;
            Ok(())
        })
    }

    pub fn get_user(&self, token: &str) -> FutureResult<UserProfile, FlowyError> {
        let token = token.to_owned();
        let url = self.config.user_profile_url();
        FutureResult::new(async move {
            let profile = get_user_profile_request(&token, &url).await?;
            Ok(profile)
        })
    }

    pub fn ws_addr(&self) -> String { self.config.ws_addr() }
}
pub struct UserLocalCloudService();
impl UserLocalCloudService {
    pub fn new(_config: &ClientServerConfiguration) -> Self { Self() }
}

impl UserLocalCloudService {
    pub fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> {
        let uid = uuid_string();
        FutureResult::new(async move {
            Ok(SignUpResponse {
                user_id: uid.clone(),
                name: params.name,
                email: params.email,
                token: uid,
            })
        })
    }

    pub fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> {
        let user_id = uuid_string();
        FutureResult::new(async {
            Ok(SignInResponse {
                user_id: user_id.clone(),
                name: params.name,
                email: params.email,
                token: user_id,
            })
        })
    }

    pub fn sign_out(&self, _token: &str) -> FutureResult<(), FlowyError> { FutureResult::new(async { Ok(()) }) }

    pub fn update_user(&self, _token: &str, _params: UpdateUserParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    pub fn get_user(&self, _token: &str) -> FutureResult<UserProfile, FlowyError> {
        FutureResult::new(async { Ok(UserProfile::default()) })
    }

    pub fn ws_addr(&self) -> String { "ws://localhost:8000/ws/".to_owned() }
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

pub async fn update_user_profile_request(token: &str, params: UpdateUserParams, url: &str) -> Result<(), ServerError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

fn request_builder() -> HttpRequestBuilder { HttpRequestBuilder::new() }
