use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UserProfile},
    errors::UserError,
};

use crate::{entities::UpdateUserParams, services::server::UserServerAPI};
use flowy_infra::future::ResultFuture;
use flowy_net::{
    config::*,
    request::{HttpRequestBuilder, ResponseMiddleware},
};

pub struct UserServer {}
impl UserServer {
    pub fn new() -> Self { Self {} }
}

impl UserServerAPI for UserServer {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        ResultFuture::new(async move { user_sign_up_request(params, SIGN_UP_URL.as_ref()).await })
    }

    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError> {
        ResultFuture::new(async move { user_sign_in_request(params, SIGN_IN_URL.as_ref()).await })
    }

    fn sign_out(&self, token: &str) -> ResultFuture<(), UserError> {
        let token = token.to_owned();
        ResultFuture::new(async move {
            let _ = user_sign_out_request(&token, SIGN_OUT_URL.as_ref()).await;
            Ok(())
        })
    }

    fn update_user(&self, token: &str, params: UpdateUserParams) -> ResultFuture<(), UserError> {
        let token = token.to_owned();
        ResultFuture::new(async move { update_user_profile_request(&token, params, USER_PROFILE_URL.as_ref()).await })
    }

    fn get_user(&self, token: &str) -> ResultFuture<UserProfile, UserError> {
        let token = token.to_owned();
        ResultFuture::new(async move { get_user_profile_request(&token, USER_PROFILE_URL.as_ref()).await })
    }
}

use crate::{errors::ErrorCode, observable::*};
use flowy_net::response::FlowyResponse;
use lazy_static::lazy_static;
use std::sync::Arc;
lazy_static! {
    static ref IDDLEWARE: Arc<Middleware> = Arc::new(Middleware {});
}

struct Middleware {}
impl ResponseMiddleware for Middleware {
    fn receive_response(&self, response: &FlowyResponse) {
        if let Some(error) = &response.error {
            if error.is_unauthorized() {
                log::error!("user unauthorized");
                let error = UserError::new(ErrorCode::UserUnauthorized, "");
                observable("", UserObservable::UserUnauthorized).error(error).build()
            }
        }
    }
}

pub(crate) fn request_builder() -> HttpRequestBuilder { HttpRequestBuilder::new().middleware(IDDLEWARE.clone()) }

pub async fn user_sign_up_request(params: SignUpParams, url: &str) -> Result<SignUpResponse, UserError> {
    let response = request_builder()
        .post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_in_request(params: SignInParams, url: &str) -> Result<SignInResponse, UserError> {
    let response = request_builder()
        .post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_out_request(token: &str, url: &str) -> Result<(), UserError> {
    let _ = request_builder().delete(&url.to_owned()).header(HEADER_TOKEN, token).send().await?;
    Ok(())
}

pub async fn get_user_profile_request(token: &str, url: &str) -> Result<UserProfile, UserError> {
    let user_profile = request_builder()
        .get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .send()
        .await?
        .response()
        .await?;
    Ok(user_profile)
}

pub async fn update_user_profile_request(token: &str, params: UpdateUserParams, url: &str) -> Result<(), UserError> {
    let _ = request_builder()
        .patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}
