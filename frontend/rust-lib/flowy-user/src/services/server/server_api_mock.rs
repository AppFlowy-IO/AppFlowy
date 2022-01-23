use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserParams, UserProfile},
    errors::FlowyError,
};

use crate::services::server::UserServerAPI;
use lib_infra::{future::FutureResult, uuid_string};

pub struct UserServerMock {}

impl UserServerMock {}

impl UserServerAPI for UserServerMock {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError> {
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

    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError> {
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

    fn sign_out(&self, _token: &str) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn update_user(&self, _token: &str, _params: UpdateUserParams) -> FutureResult<(), FlowyError> {
        FutureResult::new(async { Ok(()) })
    }

    fn get_user(&self, _token: &str) -> FutureResult<UserProfile, FlowyError> {
        FutureResult::new(async { Ok(UserProfile::default()) })
    }

    fn ws_addr(&self) -> String {
        "ws://localhost:8000/ws/".to_owned()
    }
}
