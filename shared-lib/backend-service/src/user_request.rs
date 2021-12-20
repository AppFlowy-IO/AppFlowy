use crate::{configuration::HEADER_TOKEN, errors::ServerError, request::HttpRequestBuilder};
use flowy_user_data_model::entities::prelude::*;

pub(crate) fn request_builder() -> HttpRequestBuilder {
    HttpRequestBuilder::new().middleware(crate::middleware::BACKEND_API_MIDDLEWARE.clone())
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
