use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UserDetail},
    errors::{ErrorBuilder, UserErrCode, UserError},
};

use flowy_net::{config::*, future::ResultFuture, request::HttpRequestBuilder};
use std::sync::Arc;

pub trait UserServer {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError>;
    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError>;
    fn sign_out(&self, user_id: &str) -> ResultFuture<(), UserError>;
    fn get_user_info(&self, user_id: &str) -> ResultFuture<UserDetail, UserError>;
}

pub(crate) fn construct_server() -> Arc<dyn UserServer + Send + Sync> {
    if cfg!(feature = "http_server") {
        Arc::new(UserServerImpl {})
    } else {
        Arc::new(UserServerMock {})
    }
}

pub struct UserServerImpl {}
impl UserServerImpl {
    pub fn new() -> Self { Self {} }
}

impl UserServer for UserServerImpl {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        ResultFuture::new(async move { user_sign_up(params, SIGN_UP_URL.as_ref()).await })
    }

    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError> {
        ResultFuture::new(async move { user_sign_in(params, SIGN_IN_URL.as_ref()).await })
    }

    fn sign_out(&self, _user_id: &str) -> ResultFuture<(), UserError> {
        ResultFuture::new(async { Err(ErrorBuilder::new(UserErrCode::Unknown).build()) })
    }

    fn get_user_info(&self, _user_id: &str) -> ResultFuture<UserDetail, UserError> {
        ResultFuture::new(async { Err(ErrorBuilder::new(UserErrCode::Unknown).build()) })
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

pub struct UserServerMock {}

impl UserServer for UserServerMock {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        let uid = params.email.clone();
        ResultFuture::new(async {
            Ok(SignUpResponse {
                uid,
                name: params.name,
                email: params.email,
            })
        })
    }

    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError> {
        let uid = params.email.clone();
        ResultFuture::new(async {
            Ok(SignInResponse {
                uid,
                name: params.email.clone(),
                email: params.email,
                token: "".to_string(),
            })
        })
    }

    fn sign_out(&self, _user_id: &str) -> ResultFuture<(), UserError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn get_user_info(&self, _user_id: &str) -> ResultFuture<UserDetail, UserError> {
        ResultFuture::new(async { Err(ErrorBuilder::new(UserErrCode::Unknown).build()) })
    }
}
