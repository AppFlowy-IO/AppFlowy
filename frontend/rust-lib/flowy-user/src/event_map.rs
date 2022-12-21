use crate::entities::{
    SignInParams, SignInResponse, SignUpParams, SignUpResponse, UpdateUserProfileParams, UserProfilePB,
};
use crate::{errors::FlowyError, handlers::*, services::UserSession};
use lib_dispatch::prelude::*;
use lib_infra::future::FutureResult;
use std::sync::Arc;

pub fn init(user_session: Arc<UserSession>) -> AFPlugin {
    AFPlugin::new()
        .name("Flowy-User")
        .state(user_session)
        .event(UserEvent::SignIn, sign_in)
        .event(UserEvent::SignUp, sign_up)
        .event(UserEvent::InitUser, init_user_handler)
        .event(UserEvent::GetUserProfile, get_user_profile_handler)
        .event(UserEvent::SignOut, sign_out)
        .event(UserEvent::UpdateUserProfile, update_user_profile_handler)
        .event(UserEvent::CheckUser, check_user_handler)
        .event(UserEvent::SetAppearanceSetting, set_appearance_setting)
        .event(UserEvent::GetAppearanceSetting, get_appearance_setting)
        .event(UserEvent::GetUserSetting, get_user_setting)
}

pub trait UserCloudService: Send + Sync {
    fn sign_up(&self, params: SignUpParams) -> FutureResult<SignUpResponse, FlowyError>;
    fn sign_in(&self, params: SignInParams) -> FutureResult<SignInResponse, FlowyError>;
    fn sign_out(&self, token: &str) -> FutureResult<(), FlowyError>;
    fn update_user(&self, token: &str, params: UpdateUserProfileParams) -> FutureResult<(), FlowyError>;
    fn get_user(&self, token: &str) -> FutureResult<UserProfilePB, FlowyError>;
    fn ws_addr(&self) -> String;
}

use flowy_derive::{Flowy_Event, ProtoBuf_Enum};
use strum_macros::Display;

#[derive(Clone, Copy, PartialEq, Eq, Debug, Display, Hash, ProtoBuf_Enum, Flowy_Event)]
#[event_err = "FlowyError"]
pub enum UserEvent {
    #[event()]
    InitUser = 0,

    #[event(input = "SignInPayloadPB", output = "UserProfilePB")]
    SignIn = 1,

    #[event(input = "SignUpPayloadPB", output = "UserProfilePB")]
    SignUp = 2,

    #[event(passthrough)]
    SignOut = 3,

    #[event(input = "UpdateUserProfilePayloadPB")]
    UpdateUserProfile = 4,

    #[event(output = "UserProfilePB")]
    GetUserProfile = 5,

    #[event(output = "UserProfilePB")]
    CheckUser = 6,

    #[event(input = "AppearanceSettingsPB")]
    SetAppearanceSetting = 7,

    #[event(output = "AppearanceSettingsPB")]
    GetAppearanceSetting = 8,

    #[event(output = "UserSettingPB")]
    GetUserSetting = 9,
}
