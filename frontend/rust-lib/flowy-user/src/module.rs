use crate::{errors::FlowyError, event::UserEvent, handlers::*, services::UserSession};
use flowy_user_data_model::entities::{
    SignInParams,
    SignInResponse,
    SignUpParams,
    SignUpResponse,
    UpdateUserParams,
    UserProfile,
};
use lib_dispatch::prelude::*;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub fn create(user_session: Arc<UserSession>) -> Module {
    Module::new()
        .name("Flowy-User")
        .data(user_session)
        .event(UserEvent::SignIn, sign_in)
        .event(UserEvent::SignUp, sign_up)
        .event(UserEvent::InitUser, init_user_handler)
        .event(UserEvent::GetUserProfile, get_user_profile_handler)
        .event(UserEvent::SignOut, sign_out)
        .event(UserEvent::UpdateUser, update_user_handler)
        .event(UserEvent::CheckUser, check_user_handler)
}

pub trait UserCloudService: Send + Sync {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError>;
    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError>;
    fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError>;
    fn update_user(&self, token: &str, params: UpdateUserParams) -> FutureResult<(), FlowyError>;
    fn get_user(&self, token: &str) -> FutureResult<UserProfile, FlowyError>;
    fn ws_addr(&self) -> String;
}
