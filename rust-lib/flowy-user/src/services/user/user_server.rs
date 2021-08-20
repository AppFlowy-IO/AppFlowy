use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UserDetail},
    errors::{ErrorBuilder, UserErrCode, UserError},
};

use flowy_infra::uuid;
use flowy_net::future::ResultFuture;
use std::sync::Arc;

pub(crate) trait UserServer {
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
impl UserServerImpl {}

impl UserServer for UserServerImpl {
    fn sign_up(&self, _params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        ResultFuture::new(async {
            Ok(SignUpResponse {
                uid: "".to_string(),
                name: "".to_string(),
                email: "".to_string(),
            })
        })
    }

    fn sign_in(&self, _params: SignInParams) -> ResultFuture<SignInResponse, UserError> {
        // let user_id = params.email.clone();
        // Ok(UserTable::new(
        //     user_id,
        //     "".to_owned(),
        //     params.email,
        //     params.password,
        // ))
        unimplemented!()
    }

    fn sign_out(&self, _user_id: &str) -> ResultFuture<(), UserError> {
        ResultFuture::new(async { Err(ErrorBuilder::new(UserErrCode::Unknown).build()) })
    }

    fn get_user_info(&self, _user_id: &str) -> ResultFuture<UserDetail, UserError> {
        ResultFuture::new(async { Err(ErrorBuilder::new(UserErrCode::Unknown).build()) })
    }
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
