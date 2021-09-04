mod server_api;
mod server_api_mock;
pub use server_api::*;
pub use server_api_mock::*;

use std::sync::Arc;
pub(crate) type Server = Arc<dyn UserServerAPI + Send + Sync>;
use crate::{
    entities::{SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserParams, UserProfile},
    errors::UserError,
};
use flowy_infra::future::ResultFuture;

pub trait UserServerAPI {
    fn sign_up(&self, params: SignUpParams) -> ResultFuture<SignUpResponse, UserError>;
    fn sign_in(&self, params: SignInParams) -> ResultFuture<SignInResponse, UserError>;
    fn sign_out(&self, token: &str) -> ResultFuture<(), UserError>;
    fn update_user(&self, token: &str, params: UpdateUserParams) -> ResultFuture<(), UserError>;
    fn get_user(&self, token: &str) -> ResultFuture<UserProfile, UserError>;
}

pub(crate) fn construct_user_server() -> Arc<dyn UserServerAPI + Send + Sync> {
    if cfg!(feature = "http_server") {
        Arc::new(UserServer {})
    } else {
        Arc::new(UserServerMock {})
    }
}
