use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UserDetail},
    errors::{ErrorBuilder, ErrorCode, UserError},
    services::user::UserServerAPI,
};

use crate::services::workspace::UserWorkspaceController;

use flowy_net::future::ResultFuture;
use std::sync::Arc;

pub struct UserServerMock {
    pub workspace_controller: Arc<dyn UserWorkspaceController + Send + Sync>,
}

impl UserServerMock {}

impl UserServerAPI for UserServerMock {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        let uid = params.email.clone();
        ResultFuture::new(async move {
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

    fn sign_out(&self, _token: &str) -> ResultFuture<(), UserError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn get_user_info(&self, _user_id: &str) -> ResultFuture<UserDetail, UserError> {
        ResultFuture::new(async { Err(ErrorBuilder::new(ErrorCode::Unknown).build()) })
    }
}
