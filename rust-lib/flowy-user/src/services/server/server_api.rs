use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UserDetail},
    errors::UserError,
};

use crate::{entities::UpdateUserParams, services::server::UserServerAPI};
use flowy_infra::future::ResultFuture;
use flowy_net::{config::*, request::HttpRequestBuilder};
use std::sync::Arc;

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
        ResultFuture::new(async move { update_user_detail_request(&token, params, USER_PROFILE_URL.as_ref()).await })
    }

    fn get_user_detail(&self, token: &str) -> ResultFuture<UserDetail, UserError> {
        let token = token.to_owned();
        ResultFuture::new(async move { get_user_detail_request(&token, USER_PROFILE_URL.as_ref()).await })
    }
}

pub async fn user_sign_up_request(params: SignUpParams, url: &str) -> Result<SignUpResponse, UserError> {
    let response = HttpRequestBuilder::post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_in_request(params: SignInParams, url: &str) -> Result<SignInResponse, UserError> {
    let response = HttpRequestBuilder::post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_out_request(token: &str, url: &str) -> Result<(), UserError> {
    let _ = HttpRequestBuilder::delete(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .send()
        .await?;
    Ok(())
}

pub async fn get_user_detail_request(token: &str, url: &str) -> Result<UserDetail, UserError> {
    let user_detail = HttpRequestBuilder::get(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .send()
        .await?
        .response()
        .await?;
    Ok(user_detail)
}

pub async fn update_user_detail_request(token: &str, params: UpdateUserParams, url: &str) -> Result<(), UserError> {
    let _ = HttpRequestBuilder::patch(&url.to_owned())
        .header(HEADER_TOKEN, token)
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}
