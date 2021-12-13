use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserParams, UserProfile},
    errors::UserError,
};

use crate::services::server::UserServerAPI;
use lib_infra::{future::FutureResult, uuid};

pub struct UserServerMock {}

impl UserServerMock {}

impl UserServerAPI for UserServerMock {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, UserError> {
        let uid = uuid();
        FutureResult::new(async move {
            Ok(SignUpResponse {
                user_id: uid.clone(),
                name: params.name,
                email: params.email,
                token: uid,
            })
        })
    }

    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, UserError> {
        let user_id = uuid();
        FutureResult::new(async {
            Ok(SignInResponse {
                user_id: user_id.clone(),
                name: params.name,
                email: params.email,
                token: user_id,
            })
        })
    }

    fn sign_out(&self, _token: &str) -> FutureResult<(), UserError> { FutureResult::new(async { Ok(()) }) }

    fn update_user(&self, _token: &str, _params: UpdateUserParams) -> FutureResult<(), UserError> {
        FutureResult::new(async { Ok(()) })
    }

    fn get_user(&self, _token: &str) -> FutureResult<UserProfile, UserError> {
        FutureResult::new(async { Ok(UserProfile::default()) })
    }

    fn ws_addr(&self) -> String { "ws://localhost:8000/ws/".to_owned() }
}
