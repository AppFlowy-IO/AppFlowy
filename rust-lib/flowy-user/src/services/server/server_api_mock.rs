use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UserDetail},
    errors::{ErrorBuilder, ErrorCode, UserError},
    services::user::UserServerAPI,
};

use crate::entities::UpdateUserParams;

use flowy_infra::{future::ResultFuture, uuid};

pub struct UserServerMock {}

impl UserServerMock {}

impl UserServerAPI for UserServerMock {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError> {
        let uid = uuid();
        ResultFuture::new(async move {
            Ok(SignUpResponse {
                uid,
                name: params.name,
                email: params.email,
                token: "fake token".to_owned(),
            })
        })
    }

    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError> {
        ResultFuture::new(async {
            Ok(SignInResponse {
                uid: uuid(),
                name: "fake name".to_owned(),
                email: params.email,
                token: "fake token".to_string(),
            })
        })
    }

    fn sign_out(&self, _token: &str) -> ResultFuture<(), UserError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn update_user(&self, _token: &str, _params: UpdateUserParams) -> ResultFuture<(), UserError> {
        ResultFuture::new(async { Ok(()) })
    }

    fn get_user_detail(&self, _token: &str) -> ResultFuture<UserDetail, UserError> {
        ResultFuture::new(async {
            Err(ErrorBuilder::new(ErrorCode::Unknown)
                .msg("mock data, ignore this error")
                .build())
        })
    }
}
