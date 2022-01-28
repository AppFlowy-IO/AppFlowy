use crate::{errors::FlowyError, handlers::*, services::UserSession};
use flowy_user_data_model::entities::{
    SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserParams, UserProfile,
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
        .event(UserEvent::SetAppearanceSetting, set_appearance_setting)
        .event(UserEvent::GetAppearanceSetting, get_appearance_setting)
}

pub trait UserCloudService: Send + Sync {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError>;
    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError>;
    fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError>;
    fn update_user(&self, token: &str, params: UpdateUserParams) -> FutureResult<(), FlowyError>;
    fn get_user(&self, token: &str) -> FutureResult<UserProfile, FlowyError>;
    fn ws_addr(&self) -> String;
}

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserEvent {
    #[event()]
    InitUser = 0,

    #[event(input = "SignInRequest", output = "UserProfile")]
    SignIn = 1,

    #[event(input = "SignUpRequest", output = "UserProfile")]
    SignUp = 2,

    #[event(passthrough)]
    SignOut = 3,

    #[event(input = "UpdateUserRequest")]
    UpdateUser = 4,

    #[event(output = "UserProfile")]
    GetUserProfile = 5,

    #[event(output = "UserProfile")]
    CheckUser = 6,

    #[event(input = "AppearanceSettings")]
    SetAppearanceSetting = 7,

    #[event(output = "AppearanceSettings")]
    GetAppearanceSetting = 8,
}
