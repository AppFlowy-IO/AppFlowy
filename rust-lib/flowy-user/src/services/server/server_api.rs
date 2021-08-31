use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UserDetail},
    errors::{ErrorBuilder, ErrorCode, UserError},
};

use crate::entities::UserToken;
use flowy_infra::future::ResultFuture;
use flowy_net::{config::*, request::HttpRequestBuilder};

pub trait UserServerAPI {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError>;
    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError>;
    fn sign_out(&self, token: &str) -> ResultFuture<(), UserError>;
    fn get_user_detail(&self, token: &str) -> ResultFuture<UserDetail, UserError>;
}

pub struct UserServer {}
impl UserServer {
    pub fn new() -> Self { Self {} }
}

impl UserServerAPI for UserServer {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        ResultFuture::new(async move { user_sign_up(params, SIGN_UP_URL.as_ref()).await })
    }

    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError> {
        ResultFuture::new(async move { user_sign_in(params, SIGN_IN_URL.as_ref()).await })
    }

    fn sign_out(&self, token: &str) -> ResultFuture<(), UserError> {
        let params = UserToken {
            token: token.to_string(),
        };
        ResultFuture::new(async move {
            let _ = user_sign_out(params, SIGN_OUT_URL.as_ref()).await;
            Ok(())
        })
    }

    fn get_user_detail(&self, token: &str) -> ResultFuture<UserDetail, UserError> {
        let params = UserToken {
            token: token.to_string(),
        };
        ResultFuture::new(async { get_user_detail(params, USER_DETAIL_URL.as_ref()).await })
    }
}

pub async fn user_sign_up(params: SignUpParams, url: &str) -> Result<SignUpResponse, UserError> {
    let response = HttpRequestBuilder::post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_in(params: SignInParams, url: &str) -> Result<SignInResponse, UserError> {
    let response = HttpRequestBuilder::post(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(response)
}

pub async fn user_sign_out(params: UserToken, url: &str) -> Result<(), UserError> {
    let _ = HttpRequestBuilder::delete(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?;
    Ok(())
}

pub async fn get_user_detail(params: UserToken, url: &str) -> Result<UserDetail, UserError> {
    let user_detail = HttpRequestBuilder::get(&url.to_owned())
        .protobuf(params)?
        .send()
        .await?
        .response()
        .await?;
    Ok(user_detail)
}
